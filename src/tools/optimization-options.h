/*
 * Copyright 2016 WebAssembly Community Group participants
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

#ifndef wasm_tools_optimization_options_h
#define wasm_tools_optimization_options_h

#include "tool-options.h"

//
// Shared optimization options for commandline tools
//

namespace wasm {

struct OptimizationOptions : public ToolOptions {
  static constexpr const char* DEFAULT_OPT_PASSES = "O";
  static constexpr const int OS_OPTIMIZE_LEVEL = 2;
  static constexpr const int OS_SHRINK_LEVEL = 1;

  std::vector<std::string> passes;

  constexpr static const char* OptimizationOptionsCategory =
    "Optimization options";

  OptimizationOptions(const std::string& command,
                      const std::string& description)
    : ToolOptions(command, description) {
    (*this)
      .add(
        "",
        "-O",
        "execute default optimization passes (equivalent to -Os)",
        OptimizationOptionsCategory,
        Options::Arguments::Zero,
        [this](Options*, const std::string&) {
          passOptions.setDefaultOptimizationOptions();
          static_assert(
            PassOptions::DEFAULT_OPTIMIZE_LEVEL == OS_OPTIMIZE_LEVEL &&
              PassOptions::DEFAULT_SHRINK_LEVEL == OS_SHRINK_LEVEL,
            "Help text states that -O is equivalent to -Os but now it isn't.");
          passes.push_back(DEFAULT_OPT_PASSES);
        })
      .add("",
           "-O0",
           "execute no optimization passes",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.optimizeLevel = 0;
             passOptions.shrinkLevel = 0;
           })
      .add("",
           "-O1",
           "execute -O1 optimization passes (quick&useful opts, useful for "
           "iteration builds)",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.optimizeLevel = 1;
             passOptions.shrinkLevel = 0;
             passes.push_back(DEFAULT_OPT_PASSES);
           })
      .add(
        "",
        "-O2",
        "execute -O2 optimization passes (most opts, generally gets most perf)",
        OptimizationOptionsCategory,
        Options::Arguments::Zero,
        [this](Options*, const std::string&) {
          passOptions.optimizeLevel = 2;
          passOptions.shrinkLevel = 0;
          passes.push_back(DEFAULT_OPT_PASSES);
        })
      .add("",
           "-O3",
           "execute -O3 optimization passes (spends potentially a lot of time "
           "optimizing)",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.optimizeLevel = 3;
             passOptions.shrinkLevel = 0;
             passes.push_back(DEFAULT_OPT_PASSES);
           })
      .add("",
           "-O4",
           "execute -O4 optimization passes (also flatten the IR, which can "
           "take a lot more time and memory, but is useful on more nested / "
           "complex / less-optimized input)",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.optimizeLevel = 4;
             passOptions.shrinkLevel = 0;
             passes.push_back(DEFAULT_OPT_PASSES);
           })
      .add("",
           "-Os",
           "execute default optimization passes, focusing on code size",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.optimizeLevel = OS_OPTIMIZE_LEVEL;
             passOptions.shrinkLevel = OS_SHRINK_LEVEL;
             passes.push_back(DEFAULT_OPT_PASSES);
           })
      .add("",
           "-Oz",
           "execute default optimization passes, super-focusing on code size",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.optimizeLevel = 2;
             passOptions.shrinkLevel = 2;
             passes.push_back(DEFAULT_OPT_PASSES);
           })
      .add("--optimize-level",
           "-ol",
           "How much to focus on optimizing code",
           OptimizationOptionsCategory,
           Options::Arguments::One,
           [this](Options* o, const std::string& argument) {
             passOptions.optimizeLevel = atoi(argument.c_str());
           })
      .add("--shrink-level",
           "-s",
           "How much to focus on shrinking code size",
           OptimizationOptionsCategory,
           Options::Arguments::One,
           [this](Options* o, const std::string& argument) {
             passOptions.shrinkLevel = atoi(argument.c_str());
           })
      .add("--debuginfo",
           "-g",
           "Emit names section in wasm binary (or full debuginfo in wast)",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [&](Options* o, const std::string& arguments) {
             passOptions.debugInfo = true;
           })
      .add("--always-inline-max-function-size",
           "-aimfs",
           "Max size of functions that are always inlined (default " +
             std::to_string(InliningOptions().alwaysInlineMaxSize) +
             ", which "
             "is safe for use with -Os builds)",
           OptimizationOptionsCategory,
           Options::Arguments::One,
           [this](Options* o, const std::string& argument) {
             passOptions.inlining.alwaysInlineMaxSize =
               static_cast<Index>(atoi(argument.c_str()));
           })
      .add("--flexible-inline-max-function-size",
           "-fimfs",
           "Max size of functions that are inlined when lightweight (no loops "
           "or function calls) when optimizing aggressively for speed (-O3). "
           "Default: " +
             std::to_string(InliningOptions().flexibleInlineMaxSize),
           OptimizationOptionsCategory,
           Options::Arguments::One,
           [this](Options* o, const std::string& argument) {
             passOptions.inlining.flexibleInlineMaxSize =
               static_cast<Index>(atoi(argument.c_str()));
           })
      .add("--one-caller-inline-max-function-size",
           "-ocimfs",
           "Max size of functions that are inlined when there is only one "
           "caller (default -1, which means all such functions are inlined)",
           OptimizationOptionsCategory,
           Options::Arguments::One,
           [this](Options* o, const std::string& argument) {
             static_assert(InliningOptions().oneCallerInlineMaxSize ==
                             Index(-1),
                           "the help text here is written to assume -1");
             passOptions.inlining.oneCallerInlineMaxSize =
               static_cast<Index>(atoi(argument.c_str()));
           })
      .add("--inline-functions-with-loops",
           "-ifwl",
           "Allow inlining functions with loops",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options* o, const std::string&) {
             passOptions.inlining.allowFunctionsWithLoops = true;
           })
      .add("--partial-inlining-ifs",
           "-pii",
           "Number of ifs allowed in partial inlining (zero means partial "
           "inlining is disabled) (default: " +
             std::to_string(InliningOptions().partialInliningIfs) + ')',
           OptimizationOptionsCategory,
           Options::Arguments::One,
           [this](Options* o, const std::string& argument) {
             passOptions.inlining.partialInliningIfs =
               static_cast<Index>(std::stoi(argument));
           })
      .add("--ignore-implicit-traps",
           "-iit",
           "Optimize under the helpful assumption that no surprising traps "
           "occur (from load, div/mod, etc.)",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.ignoreImplicitTraps = true;
           })
      .add("--traps-never-happen",
           "-tnh",
           "Optimize under the helpful assumption that no trap is reached at "
           "runtime (from load, div/mod, etc.)",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.trapsNeverHappen = true;
           })
      .add("--low-memory-unused",
           "-lmu",
           "Optimize under the helpful assumption that the low 1K of memory is "
           "not used by the application",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.lowMemoryUnused = true;
           })
      .add(
        "--fast-math",
        "-ffm",
        "Optimize floats without handling corner cases of NaNs and rounding",
        OptimizationOptionsCategory,
        Options::Arguments::Zero,
        [this](Options*, const std::string&) { passOptions.fastMath = true; })
      .add(
        "--closed-world",
        "-cw",
        "Assume code outside of the module does not inspect or interact with "
        "GC and function references, even if they are passed out. The outside "
        "may hold on to them and pass them back in, but not inspect their "
        "contents or call them.",
        OptimizationOptionsCategory,
        Options::Arguments::Zero,
        [this](Options*, const std::string&) {
          passOptions.closedWorld = true;
        })
      .add("--zero-filled-memory",
           "-uim",
           "Assume that an imported memory will be zero-initialized",
           OptimizationOptionsCategory,
           Options::Arguments::Zero,
           [this](Options*, const std::string&) {
             passOptions.zeroFilledMemory = true;
           });

    // add passes in registry
    for (const auto& p : PassRegistry::get()->getRegisteredNames()) {
      (*this).add(
        std::string("--") + p,
        "",
        PassRegistry::get()->getPassDescription(p),
        "Optimization passes",
        // Allow an optional parameter to a pass. If provided, it is
        // the same as if using --pass-arg, that is,
        //
        //   --foo=ARG
        //
        // is the same as
        //
        //   --foo --pass-arg=foo@ARG
        Options::Arguments::Optional,
        [this, p](Options*, const std::string& arg) {
          if (!arg.empty()) {
            if (passOptions.arguments.count(p)) {
              Fatal() << "Cannot pass multiple pass arguments to " << p;
            }
            passOptions.arguments[p] = arg;
          }
          passes.push_back(p);
        },
        PassRegistry::get()->isPassHidden(p));
    }
  }

  bool runningDefaultOptimizationPasses() {
    for (auto& pass : passes) {
      if (pass == DEFAULT_OPT_PASSES) {
        return true;
      }
    }
    return false;
  }

  bool runningPasses() { return passes.size() > 0; }

  void runPasses(Module& wasm) {
    PassRunner passRunner(&wasm, passOptions);
    if (debug) {
      passRunner.setDebug(true);
    }
    for (auto& pass : passes) {
      if (pass == DEFAULT_OPT_PASSES) {
        passRunner.addDefaultOptimizationPasses();
      } else {
        passRunner.add(pass);
      }
    }
    passRunner.run();
  }
};

} // namespace wasm

#endif
