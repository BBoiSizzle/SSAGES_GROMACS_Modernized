#pragma once

#include "Meta.h"
#ifdef SSAGES_GPU_ENABLED
#include <json/json.h>

namespace SSAGES {
class MetaGPUAccelerated : public Meta {
public:
    using Meta::Meta;
    MetaGPUAccelerated(const Meta& other) : Meta(other) {}

    static MetaGPUAccelerated* Build(const Json::Value& json,
                                     const MPI_Comm& world,
                                     const MPI_Comm& comm,
                                     const std::string& path);
protected:
    void CalcBiasForce(const CVList& cvs) override;
};
}
#endif
