/*
 * Copyright 2019 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
// Turn indirect calls into direct calls. This is possible if we know
// the table cannot change, and if we see a constant argument for the
// indirect call's index.
//

#include <unordered_map>

#include "ir/table-utils.h"
#include "ir/type-updating.h"
#include "ir/utils.h"
#include "pass.h"
#include "wasm-builder.h"
#include "wasm-traversal.h"
#include "wasm.h"

namespace wasm {

namespace {

struct FunctionDirectizer : public WalkerPass<PostWalker<FunctionDirectizer>> {
  bool isFunctionParallel() override { return true; }

  Pass* create() override { return new FunctionDirectizer(tables); }

  FunctionDirectizer(
    const std::unordered_map<Name, TableUtils::FlatTable>& tables)
    : tables(tables) {}

  void visitCallIndirect(CallIndirect* curr) {
    auto it = tables.find(curr->table);
    if (it == tables.end()) {
      return;
    }

    auto& flatTable = it->second;

    // Size 0? trapp!

    // Replace all call_indirects to flat immutable tables with a call to a function with a switch?

    // Given an expression, get an index from it if it is a constant, and if not
    // then use a given default.
    auto getIndex = [](Expression* expr, Index default_) -> Index {
      if (expr) {
        if (auto* c = expr->dynCast<Const>()) {
          return c->value.geti32();
        }
      }
      return default_;
    };

    // If the target is constant, we can emit a direct call.
    // FIXME: 1 and 2 depend on TNH
    if (curr->target->is<Const>() || flatTable.names.size() == 1) {
      std::vector<Expression*> operands(curr->operands.begin(),
                                        curr->operands.end());
      // FIXME 0 and 0 and 1 below are wrong! Must be indexes of the things in the table.
      // FIXME also really this isn't the size of the tale per say but the
      // existence of only 1 or 2 non-null items in itt.
      replaceCurrent(
        makeDirectCall(operands, getIndex(curr->target, 0), flatTable, curr));
      return;
    }

    // If the target is a select of two different constants, we can emit two
    // direct calls.
    // TODO: handle 3+
    // TODO: handle the case where just one arm is a constant?
    auto* select = curr->target->dynCast<Select>();
    if ((select && select->ifTrue->is<Const>() &&
         select->ifFalse->is<Const>()) ||
        flatTable.names.size() == 2) {
      Builder builder(*getModule());
      auto* func = getFunction();
      std::vector<Expression*> blockContents;

      // We must use the operands twice, and also must move the condition to
      // execute first; use locals for them all. While doing so, if we see
      // any are unreachable, stop trying to optimize and leave this for DCE.
      std::vector<Index> operandLocals;
      for (auto* operand : curr->operands) {
        if (operand->type == Type::unreachable ||
            !TypeUpdating::canHandleAsLocal(operand->type)) {
          return;
        }
        auto currLocal = builder.addVar(func, operand->type);
        operandLocals.push_back(currLocal);
        blockContents.push_back(builder.makeLocalSet(currLocal, operand));
      }

      if (select && select->condition->type == Type::unreachable) {
        return;
      }
      if (!select && curr->type == Type::unreachable) {
        return;
      }

      // Build the calls.
      auto numOperands = curr->operands.size();
      auto getOperands = [&]() {
        std::vector<Expression*> newOperands(numOperands);
        for (Index i = 0; i < numOperands; i++) {
          newOperands[i] =
            builder.makeLocalGet(operandLocals[i], curr->operands[i]->type);
        }
        return newOperands;
      };
      auto* ifTrueCall = makeDirectCall(
        getOperands(), getIndex(select ? select->ifTrue : nullptr, 1), flatTable, curr);
      auto* ifFalseCall = makeDirectCall(
        getOperands(), getIndex(select ? select->ifFalse : nullptr, 0), flatTable, curr);

      // TODO: move up and use for unreachability
      Expression* condition;
      if (select) {
        condition = select->condition;
      } else {
        condition = curr->target;
      }

      // Create the if to pick the calls, and emit the final block.
      auto* iff = builder.makeIf(condition, ifTrueCall, ifFalseCall);
      blockContents.push_back(iff);
      replaceCurrent(builder.makeBlock(blockContents));

      // By adding locals we must make type adjustments at the end.
      changedTypes = true;
    }
  }

  void doWalkFunction(Function* func) {
    WalkerPass<PostWalker<FunctionDirectizer>>::doWalkFunction(func);
    if (changedTypes) {
      ReFinalize().walkFunctionInModule(func, getModule());
      TypeUpdating::handleNonDefaultableLocals(func, *getModule());
    }
  }

private:
  const std::unordered_map<Name, TableUtils::FlatTable>& tables;

  bool changedTypes = false;

  // Create a direct call for a given list of operands, an expression which is
  // known to contain a constant indicating the table offset, and the relevant
  // table. If we can see that the call will trap, instead return an
  // unreachable.
  Expression* makeDirectCall(const std::vector<Expression*>& operands,
                             Index index,
                             const TableUtils::FlatTable& flatTable,
                             CallIndirect* original) {

    // If the index is invalid, or the type is wrong, we can
    // emit an unreachable here, since in Binaryen it is ok to
    // reorder/replace traps when optimizing (but never to
    // remove them, at least not by default).
    if (index >= flatTable.names.size()) {
      return replaceWithUnreachable(operands);
    }
    auto name = flatTable.names[index];
    if (!name.is()) {
      return replaceWithUnreachable(operands);
    }
    auto* func = getModule()->getFunction(name);
    if (original->sig != func->getSig()) {
      return replaceWithUnreachable(operands);
    }

    // Everything looks good!
    return Builder(*getModule())
      .makeCall(name, operands, original->type, original->isReturn);
  }

  Expression* replaceWithUnreachable(const std::vector<Expression*>& operands) {
    // Emitting an unreachable means we must update parent types.
    changedTypes = true;

    Builder builder(*getModule());
    std::vector<Expression*> newOperands;
    for (auto* operand : operands) {
      newOperands.push_back(builder.makeDrop(operand));
    }
    return builder.makeSequence(builder.makeBlock(newOperands),
                                builder.makeUnreachable());
  }
};

struct Directize : public Pass {
  void run(PassRunner* runner, Module* module) override {
    // Find which tables are valid to optimize on. They must not be imported nor
    // exported (so the outside cannot modify them), and must have no sets in
    // any part of the module.

    // First, find which tables have sets.
    using TablesWithSet = std::unordered_set<Name>;

    ModuleUtils::ParallelFunctionAnalysis<TablesWithSet> analysis(
      *module, [&](Function* func, TablesWithSet& tablesWithSet) {
        if (func->imported()) {
          return;
        }
        for (auto* set : FindAll<TableSet>(func->body).list) {
          tablesWithSet.insert(set->table);
        }
      });

    TablesWithSet tablesWithSet;
    for (auto& kv : analysis.map) {
      for (auto name : kv.second) {
        tablesWithSet.insert(name);
      }
    }

    std::unordered_map<Name, TableUtils::FlatTable> validTables;

    for (auto& table : module->tables) {
      if (table->imported()) {
        continue;
      }

      if (tablesWithSet.count(table->name)) {
        continue;
      }

      bool canOptimizeCallIndirect = true;
      for (auto& ex : module->exports) {
        if (ex->kind == ExternalKind::Table && ex->value == table->name) {
          canOptimizeCallIndirect = false;
          break;
        }
      }
      if (!canOptimizeCallIndirect) {
        continue;
      }

      // All conditions are valid, this is optimizable.
      TableUtils::FlatTable flatTable(*module, *table);
      if (flatTable.valid) {
        validTables.emplace(table->name, flatTable);
      }
    }

    // Without typed function references, all we can do is optimize table
    // accesses, so if we can't do that, stop.
    if (validTables.empty() && !module->features.hasTypedFunctionReferences()) {
      return;
    }
    // The table exists and is constant, so this is possible.
    FunctionDirectizer(validTables).run(runner, module);
  }
};

} // anonymous namespace

Pass* createDirectizePass() { return new Directize(); }

} // namespace wasm
