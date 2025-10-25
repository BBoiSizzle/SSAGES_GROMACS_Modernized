#include "MetaGPU.h"
#ifdef SSAGES_GPU_ENABLED
#include <cuda_runtime.h>
#include <vector>
#include <cmath>

namespace SSAGES {
__device__ double gpu_gaussian(double dx, double sigma) {
    return exp(-0.5 * dx * dx / (sigma * sigma));
}

__device__ double gpu_gaussian_deriv(double dx, double sigma) {
    return (-dx / (sigma * sigma)) * exp(-0.5 * dx * dx / (sigma * sigma));
}

__global__ void meta_bias_kernel(const double* cv,
                                 const double* centers,
                                 const double* widths,
                                 const double* heights,
                                 int ncv,
                                 int nhills,
                                 double* derivatives) {
    int i = threadIdx.x;
    if (i < ncv)
        derivatives[i] = 0.0;
    __syncthreads();

    for (int h = 0; h < nhills; ++h) {
        double dx[8];
        double tbias = 1.0;
        for (int j = 0; j < ncv; ++j) {
            dx[j] = cv[j] - centers[h * ncv + j];
            tbias *= gpu_gaussian(dx[j], widths[h * ncv + j]);
        }
        for (int j = 0; j < ncv; ++j) {
            double term = heights[h];
            for (int k = 0; k < ncv; ++k) {
                if (k == j)
                    term *= gpu_gaussian_deriv(dx[k], widths[h * ncv + k]);
                else
                    term *= gpu_gaussian(dx[k], widths[h * ncv + k]);
            }
            atomicAdd(&derivatives[j], term);
        }
    }
}

MetaGPUAccelerated* MetaGPUAccelerated::Build(const Json::Value& json,
                                              const MPI_Comm& world,
                                              const MPI_Comm& comm,
                                              const std::string& path) {
    Meta* base = Meta::Build(json, world, comm, path);
    auto* derived = new MetaGPUAccelerated(*base);
    delete base;
    return derived;
}

void MetaGPUAccelerated::CalcBiasForce(const CVList& cvs) {
    auto n = cvs.size();
    size_t nhills = hills_.size();
    std::fill(derivatives_.begin(), derivatives_.end(), 0.0);
    if (n == 0 || nhills == 0)
        return;

    std::vector<double> cv(n);
    for (size_t i = 0; i < n; ++i)
        cv[i] = cvs[i]->GetValue();

    std::vector<double> centers(nhills * n), widths(nhills * n), heights(nhills);
    for (size_t h = 0; h < nhills; ++h) {
        for (size_t j = 0; j < n; ++j) {
            centers[h * n + j] = hills_[h].center[j];
            widths[h * n + j] = hills_[h].width[j];
        }
        heights[h] = hills_[h].height;
    }

    double *d_cv, *d_centers, *d_widths, *d_heights, *d_derivatives;
    cudaMalloc(&d_cv, n * sizeof(double));
    cudaMalloc(&d_centers, nhills * n * sizeof(double));
    cudaMalloc(&d_widths, nhills * n * sizeof(double));
    cudaMalloc(&d_heights, nhills * sizeof(double));
    cudaMalloc(&d_derivatives, n * sizeof(double));

    cudaMemcpy(d_cv, cv.data(), n * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_centers, centers.data(), nhills * n * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_widths, widths.data(), nhills * n * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_heights, heights.data(), nhills * sizeof(double), cudaMemcpyHostToDevice);

    meta_bias_kernel<<<1, n>>>(d_cv, d_centers, d_widths, d_heights, n, nhills, d_derivatives);
    cudaMemcpy(derivatives_.data(), d_derivatives, n * sizeof(double), cudaMemcpyDeviceToHost);

    cudaFree(d_cv);
    cudaFree(d_centers);
    cudaFree(d_widths);
    cudaFree(d_heights);
    cudaFree(d_derivatives);

    for (size_t i = 0; i < n; ++i) {
        auto cval = cvs[i]->GetValue();
        if (cval < lowerb_[i])
            derivatives_[i] += lowerk_[i] * (cval - lowerb_[i]);
        else if (cval > upperb_[i])
            derivatives_[i] += upperk_[i] * (cval - upperb_[i]);
    }
}

} // namespace SSAGES
#endif
