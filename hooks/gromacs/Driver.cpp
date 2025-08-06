/**
 * This file is part of
 * SSAGES - Software Suite for Advanced General Ensemble Simulations
 *
 * Copyright 2017 Hythem Sidky <hsidky@nd.edu>
 *
 * SSAGES is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SSAGES is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SSAGES.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "Driver.h"
#include "GromacsHook.h"
#include "ResourceHandler.h"
#include "json/json.h"
#include <sstream>

// Since SSAGES is now specifically configured to build against GROMACS 2024.4,
// we'll use the modern gmxapi exclusively
#define USE_MODERN_GROMACS_API
#include "gmxapi/gmxapi.h"
#include "gmxapi/context.h"
#include "gmxapi/session.h"
#include "gmxapi/md.h"
#include "gmxapi/system.h"

namespace SSAGES
{
	void Driver::Run()
	{
		// Handle different GROMACS API versions
#ifdef USE_MODERN_GROMACS_API
        // Modern GROMACS API (2024+) using gmxapi
        try {
            // Extract TPR filename from arguments (typically -s argument)
            std::string tprFilename;
            for(size_t i = 0; i < args_.size(); ++i) {
                if(args_[i] == "-s" && i + 1 < args_.size()) {
                    tprFilename = args_[i + 1];
                    break;
                }
            }
            
            if(tprFilename.empty()) {
                throw std::runtime_error("No TPR file specified in arguments. Modern GROMACS API requires a TPR file (-s option).");
            }
            
            std::cout << "Using TPR file: " << tprFilename << std::endl;
            
            // Create a GROMACS system from TPR file
            auto system = gmxapi::fromTprFile(tprFilename);
            
            // Create a GROMACS execution context as shared_ptr
            auto context = std::make_shared<gmxapi::Context>(gmxapi::createContext());
            
            // Launch the system to create a session
            auto session = system.launch(context);
            
            // Run the simulation
            session->run();
            session->close();
            
            std::cout << "GROMACS simulation completed successfully." << std::endl;
            
        } catch (const std::exception& e) {
            std::cerr << "Error in modern GROMACS API: " << e.what() << std::endl;
            throw;
        }
#else
        // Legacy GROMACS API - build argc/argv like before
        int argc = args_.size() + 1 + ((rh_->GetNumWalkers() > 1) ? 2 : 0);
        char **argv = new char*[argc];
        for(int i = 0; i < argc; ++i)
            argv[i] = new char[128];
        
        sprintf(argv[0], "ssages");
        for(size_t i = 0; i < args_.size(); ++i)
            strcpy(argv[i+1], args_[i].c_str());
        
        if(rh_->GetNumWalkers() > 1)
        {
            sprintf(argv[args_.size()+1], "-multi");
            sprintf(argv[args_.size()+2], "%i", static_cast<int>(rh_->GetNumWalkers()));
        }

        std::cout << std::endl;
        
        // Use legacy CommandLineModuleManager
        CommandLineModuleManager::runAsMainCMain(argc, argv, &gmx_mdrun);
        
        // Clean up
        for(int i = 0; i < argc; ++i)
            delete[] argv[i];
        delete[] argv;
#endif
	}
	
	Driver* Driver::Build(const Json::Value& json, const MPI_Comm& world)
	{
		auto* rh = ResourceHandler::Build(json, world);
		auto& hook = GromacsHook::Instance();
		rh->ConfigureHook(dynamic_cast<Hook*>(&hook));

		std::vector<std::string> args;
		if(json["args"].isArray())
		{
			for(auto& s : json["args"])
				args.push_back(s.asString());
		}
		else
		{
			std::istringstream iss(json["args"].asString());
			args = std::vector<std::string>(std::istream_iterator<std::string>{iss},
			                                std::istream_iterator<std::string>());
		}

		return new Driver(rh, args);
	}

	Driver::~Driver()
	{
		delete rh_;
	}
}
