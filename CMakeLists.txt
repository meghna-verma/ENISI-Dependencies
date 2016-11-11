cmake_minimum_required(VERSION 2.8.8)
include(ExternalProject)

set(INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/install)

find_package(MPI)

if (MPI_CXX_FOUND)
  message(STATUS "-----------------------------------------------------------
    MPI_CXX_COMPILER        ${MPI_CXX_COMPILER}
    MPI_CXX_COMPILE_FLAGS   ${MPI_CXX_COMPILE_FLAGS}
    MPI_CXX_INCLUDE_PATH    ${MPI_CXX_INCLUDE_PATH}
    MPI_CXX_LINK_FLAGS      ${MPI_CXX_LINK_FLAGS}
    MPI_CXX_LIBRARIES       ${MPI_CXX_LIBRARIES}
  ")

  set(REPAST_INSTALL_MPI OFF)
else()
  set(MPI_CXX_COMPILER "")
  set(REPAST_INSTALL_MPI ON)
endif()

set(REPAST_DIR ${CMAKE_BINARY_DIR}/src/project_repast)
set(REPAST_EXT_DIR ${REPAST_DIR}/ext)
set(REPAST_INSTALL_DIR ${REPAST_DIR}/INSTALLATION)

ExternalProject_Add(project_repast
  DOWNLOAD_DIR     
  LOG_DOWNLOAD 1   # Wrap download in script to log output
  DOWNLOAD_COMMAND  tar -C ${REPAST_DIR} -xvf ${PROJECT_SOURCE_DIR}/RHPC_2.0.tar.gz --strip-components=2
  PREFIX ${CMAKE_BINARY_DIR}
  CONFIGURE_COMMAND ""

  PATCH_COMMAND ${CMAKE_COMMAND} -DBUILD_STEP=patch
    -DREPAST_DIR=${REPAST_DIR}
    -DPATCH_DIR=${PROJECT_SOURCE_DIR}/patches
    -DLOG_DIR=${CMAKE_BINARY_DIR}
    -P ${PROJECT_SOURCE_DIR}/project_repast.cmake

  #--Build step-----------------
  BUILD_IN_SOURCE 1 # Use source dir for build dir
  BUILD_COMMAND cmake -DBUILD_STEP=install -DWORK_DIR=${REPAST_INSTALL_DIR} 
    -DMPI_CXX_COMPILER=${MPI_CXX_COMPILER}
    -DMPI_CXX_LINK_FLAGS=${MPI_CXX_LINK_FLAGS}
    -DLOG_DIR=${CMAKE_BINARY_DIR}
    -DREPAST_EXT_DIR=${REPAST_EXT_DIR}
    -P ${PROJECT_SOURCE_DIR}/project_repast.cmake

  INSTALL_COMMAND ${PROJECT_SOURCE_DIR}/project_repast-install.sh ${INSTALL_PREFIX} ${CMAKE_BINARY_DIR}/src ${REPAST_INSTALL_MPI}
)

set(COPASI_DEPS_DIR ${CMAKE_BINARY_DIR}/src/project_copasi_deps)

if (APPLE)
  set(COPASI_DEPS_BUILD_COMMAND ${COPASI_DEPS_DIR}/createOSX.sh)
else()
  set(COPASI_DEPS_BUILD_COMMAND ${COPASI_DEPS_DIR}/createLinux.sh)
endif()

ExternalProject_Add(project_copasi_deps
  DOWNLOAD_DIR      
  LOG_DOWNLOAD 1   # Wrap download in script to log output
  GIT_REPOSITORY https://github.com/copasi/copasi-dependencies
  GIT_TAG fb30446b0fd97dc0b936921d781e2a25e6514d02
  PREFIX ${CMAKE_BINARY_DIR}

  UPDATE_COMMAND "" # Prevent a GIT PULL request
  CONFIGURE_COMMAND ""

  #--Build step-----------------
  LOG_BUILD 1       # Wrap build in script to log output
  BUILD_IN_SOURCE 1 # Use source dir for build dir

  BUILD_COMMAND ${COPASI_DEPS_BUILD_COMMAND} expat raptor clapack libSBML libSEDML

  INSTALL_COMMAND ${PROJECT_SOURCE_DIR}/project_copasi_deps-install.sh ${INSTALL_PREFIX} ${CMAKE_BINARY_DIR}/src
)

set(COPASI_DIR ${CMAKE_BINARY_DIR}/src/project_copasi)

ExternalProject_Add(project_copasi
  DOWNLOAD_DIR      
  LOG_DOWNLOAD 1   # Wrap download in script to log output
  GIT_REPOSITORY https://github.com/copasi/COPASI
  GIT_TAG Build-104
  PREFIX ${CMAKE_BINARY_DIR}

  UPDATE_COMMAND "" # Prevent a GIT PULL request

  #--Configure step-----------------
  #!!DON'T UNCOMMENT LOG_CONFIGURE FOR THIS PROJECT!!!!!
  #--Doing so will break the configure step on Shadowfax--
  #LOG_CONFIGURE 1      # Wrap configure in script to log output

  CONFIGURE_COMMAND cmake -DBUILD_GUI=OFF
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
    -DCOPASI_DEPENDENCY_DIR=${INSTALL_PREFIX}
    ../project_copasi 


  #--Build step-----------------
  LOG_BUILD 1       # Wrap build in script to log output
  BUILD_COMMAND make -j 4

  #--Install step-----------------
  LOG_INSTALL 1       # Wrap install in script to log output
  INSTALL_COMMAND ${PROJECT_SOURCE_DIR}/project_copasi-install.sh ${INSTALL_PREFIX} ${CMAKE_BINARY_DIR}/src
)

add_dependencies(project_copasi project_copasi_deps)

