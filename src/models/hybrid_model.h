// Copyright (c) 2023 Intel Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ============================================================================
#pragma once
#include <vector>
#include "abstract_decoder.h"
#include "numa_allocator.h"
#include <type_traits>

template <template <typename> class Model, typename FirstTokenDtype, typename NextTokenDtype>
class HybridModel : public AbstractDecoder {
public:
    HybridModel(const std::string &modelPath) {
        // The weight location configured in "FIRST_TOKEN_WEIGHT_LOCATION" and "NEXT_TOKEN_WEIGHT_LOCATION"
        int firstNode = getenv("FIRST_TOKEN_WEIGHT_LOCATION") ? atoi(getenv("FIRST_TOKEN_WEIGHT_LOCATION")) : -1;
        xft_set_preferred_node(firstNode);
        firstModel = new Model<FirstTokenDtype>(modelPath);

        int nextNode = getenv("NEXT_TOKEN_WEIGHT_LOCATION") ? atoi(getenv("NEXT_TOKEN_WEIGHT_LOCATION")) : -1;
        xft_set_preferred_node(nextNode);
        nextModel = new Model<NextTokenDtype>(modelPath);

        // Reset
        xft_set_preferred_node(-1);
    }

    ~HybridModel() {
        delete nextModel;
        delete firstModel;
    }

    std::tuple<float *, int, int> forward(int *ids, int64_t *dims, int step, bool logitsAll = false) {
        if (step == 0) {
            // Record the prompt information for future usage
            // Assume the input's shape is [userSideBS][1][seqLen].
            this->firstStepBS = dims[0];
            this->firstStepSeqLen = dims[2];
            promptIds.resize(dims[0] * dims[2]);
            std::copy(ids, ids + dims[0] * dims[2], promptIds.begin());

            return firstModel->forward(ids, dims, step, logitsAll);
        } else {
            // Make everything ready as step==0 is skipped in nextModel
            if (step == 1) {
                nextModel->setSharedResources(firstModel->getSharedResources());

                // Models like ChatGLM need to get prepared for some token information from prompt IDs
                if constexpr (std::is_invocable_v<decltype(&Model<NextTokenDtype>::getPositionIds),
                                      Model<NextTokenDtype>, int *, int, int, int>) {
                    nextModel->getPositionIds(promptIds.data(), firstStepBS, firstStepSeqLen, 0);
                }

                int initSeqLen = firstModel->getInitSeqLen();
                nextModel->skipFirstStep(initSeqLen);
            }

            return nextModel->forward(ids, dims, step, logitsAll);
        }
    }

    void reorderCache(int *idx, int size) { return firstModel->reorderCache(idx, size); }

    DecoderContext *getContext() { return firstModel->getContext(); }

    Messenger &getMessenger() { return firstModel->getMessenger(); }

    int getRank() { return firstModel->getRank(); }

    int getEndId() { return firstModel->getEndId(); }

private:
    Model<FirstTokenDtype> *firstModel;
    Model<NextTokenDtype> *nextModel;

    std::vector<int> promptIds;
    int firstStepBS;
    int firstStepSeqLen;
};