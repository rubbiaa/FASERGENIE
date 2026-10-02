
	cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
	atlas_subdir(TPythia6)

	find_package( ROOT REQUIRED COMPONENTS Core EG Graf Physics )
	find_package( Pythia6 )
	

	include_directories(${CMAKE_CURRENT_SOURCE_DIR}/TPythia6)	

	atlas_add_root_dictionary( EGPythia6 EGPythia6CintDict
	ROOT_HEADERS TPythia6/TMCParticle.h TPythia6/TPythia6.h TPythia6/TPythia6Decayer.h TPythia6/LinkDef.h
	EXTERNAL_PACKAGES ROOT )

	atlas_add_library(EGPythia6 
					${EGPythia6CintDict}
					src/TMCParticle.cxx
					src/TPythia6.cxx
					src/TPythia6Decayer.cxx
					PUBLIC_HEADERS TPythia6
					INCLUDE_DIRS ${PYTHIA6_INCLUDE_DIRS} ${ROOT_INCLUDE_DIRS} 
					LINK_LIBRARIES ${PYTHIA6_LIBRARIES} 
								   ${PYTHIA6_LIBRARY_DIRS}/librootinterface.so 
								   ${PYTHIA6_LIBRARY_DIRS}/libpythia6_dummy.so
								   ${PYTHIA6_LIBRARY_DIRS}/pydata.o
								   ${ROOT_LIBRARIES})

