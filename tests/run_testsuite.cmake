## ---------------------------------------------------------------------
##
## Copyright (C) 2013 - 2018 by the deal.II authors
##
## This file is part of the deal.II library.
##
## The deal.II library is free software; you can use it, redistribute
## it, and/or modify it under the terms of the GNU Lesser General
## Public License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
## The full text of the license can be found in the file LICENSE.md at
## the top level directory of deal.II.
##
## ---------------------------------------------------------------------


########################################################################
#                                                                      #
#                             Test setup:                              #
#                                                                      #
########################################################################

#
# This is the ctest script for running and submitting build and regression
# tests.
#
# Invoke it in a _build directory_ (or designated build directory) via:
#
#   ctest -S <...>/run_testsuite.cmake
#
# The following configuration variables can be overwritten with
#
#   ctest -D<variable>=<value> [...]
#
#
#   CTEST_SOURCE_DIRECTORY
#     - The source directory of deal.II
#     - If unspecified, "../" relative to the location of this script is
#       used. If this is not a source directory, an error is thrown.
#
#   CTEST_BINARY_DIRECTORY
#     - The designated build directory (already configured, empty, or non
#       existent - see the information about TRACKs what will happen)
#     - If unspecified the current directory is used. If the current
#       directory is equal to CTEST_SOURCE_DIRECTORY or the "tests"
#       directory, an error is thrown.
#
#   CTEST_CMAKE_GENERATOR
#     - The CMake Generator to use (e.g. "Unix Makefiles", or "Ninja", see
#       $ man cmake)
#     - If unspecified the current generator of a configured build directory
#       will be used, otherwise "Unix Makefiles".
#
#   TRACK
#     - The track the test should be submitted to. Defaults to
#       "Experimental". Possible values are:
#
#       "Experimental"     - all tests that are not specifically "build" or
#                            "regression" tests should go into this track
#
#       "Build Tests"      - Build tests that configure and build in a clean
#                            directory (without actually running the
#                            testsuite)
#
#       "Regression Tests" - Reserved for "official" regression testers
#
#       "Continuous"       - Reserved for "official" regression testers
#
#   CONFIG_FILE
#     - A configuration file (see ../doc/users/config.sample)
#       that will be used during the configuration stage (invokes
#       # cmake -C ${CONFIG_FILE}). This only has an effect if
#       CTEST_BINARY_DIRECTORY is empty.
#
#   DESCRIPTION
#     - A string that is appended to CTEST_BUILD_NAME
#
#   COVERAGE
#     - If set to ON deal.II will be configured with
#     DEAL_II_SETUP_COVERAGE=ON, CMAKE_BUILD_TYPE=Debug and the
#     CTEST_COVERAGE() stage will be run. Test results must go into the
#     "Experimental" section.
#
#   MEMORYCHECK
#     - If set to ON the CTEST_MEMORYCHECK() stage will be run.
#     Test results must go into the "Experimental" section.
#
#   MAKEOPTS
#     - Additional options that will be passed directly to make (or ninja).
#
# Furthermore, the following variables controlling the testsuite can be set
# and will be automatically handed down to cmake:
#
#   NUMDIFF_DIR
#   DIFF_DIR
#   TEST_TIME_LIMIT
#   TEST_PICKUP_REGEX
#
# For details, consult the ./README file.
#

CMAKE_MINIMUM_REQUIRED(VERSION 3.3.0)
MESSAGE("-- This is CTest ${CMAKE_VERSION}")

#
# TRACK: Default to Experimental:
#

IF("${TRACK}" STREQUAL "")
  SET(TRACK "Experimental")
ENDIF()

IF( NOT "${TRACK}" STREQUAL "Experimental"
    AND NOT "${TRACK}" STREQUAL "Build Tests"
    AND NOT "${TRACK}" STREQUAL "Regression Tests"
    AND NOT "${TRACK}" STREQUAL "Continuous" )
  MESSAGE(FATAL_ERROR "
Unknown TRACK \"${TRACK}\" - see the manual for valid values.
"
    )
ENDIF()

MESSAGE("-- TRACK:                  ${TRACK}")

#
# CTEST_SOURCE_DIRECTORY:
#

IF("${CTEST_SOURCE_DIRECTORY}" STREQUAL "")
  #
  # If CTEST_SOURCE_DIRECTORY is not set we just assume that this script
  # was called residing under ./tests in the source directory
  #
  GET_FILENAME_COMPONENT(CTEST_SOURCE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" PATH)

  IF(NOT EXISTS ${CTEST_SOURCE_DIRECTORY}/CMakeLists.txt)
    MESSAGE(FATAL_ERROR "
Could not find a suitable source directory. There is no source directory
\"../\" relative to the location of this script. Please, set
CTEST_SOURCE_DIRECTORY manually to the appropriate source directory.
"
      )
  ENDIF()
ENDIF()

MESSAGE("-- CTEST_SOURCE_DIRECTORY: ${CTEST_SOURCE_DIRECTORY}")

#
# Read in custom config files:
#

CTEST_READ_CUSTOM_FILES(${CTEST_SOURCE_DIRECTORY})

#
# CTEST_BINARY_DIRECTORY:
#

IF("${CTEST_BINARY_DIRECTORY}" STREQUAL "")
  #
  # If CTEST_BINARY_DIRECTORY is not set we just use the current directory
  # except if it is equal to CTEST_SOURCE_DIRECTORY in which case we fail.
  #
  SET(CTEST_BINARY_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

  IF( ( "${CTEST_BINARY_DIRECTORY}" STREQUAL "${CTEST_SOURCE_DIRECTORY}"
        AND NOT EXISTS ${CTEST_SOURCE_DIRECTORY}/CMakeCache.txt )
      OR "${CTEST_BINARY_DIRECTORY}" STREQUAL "${CMAKE_CURRENT_LIST_DIR}" )
    MESSAGE(FATAL_ERROR "
ctest was invoked in the source directory or under ./tests and
CTEST_BINARY_DIRECTORY is not set. Please either call ctest from within a
designated build directory, or set CTEST_BINARY_DIRECTORY accordingly.
"
      )
  ENDIF()
ENDIF()

#
# Read in custom config files:
#

CTEST_READ_CUSTOM_FILES(${CTEST_BINARY_DIRECTORY})

# Make sure that for a build test the directory is empty:
FILE(GLOB _test ${CTEST_BINARY_DIRECTORY}/*)
IF( "${TRACK}" STREQUAL "Build Tests"
    AND NOT "${_test}" STREQUAL "" )
      MESSAGE(FATAL_ERROR "
TRACK was set to \"Build Tests\" which require an empty build directory.
But files were found in \"${CTEST_BINARY_DIRECTORY}\"
"
        )
ENDIF()

MESSAGE("-- CTEST_BINARY_DIRECTORY: ${CTEST_BINARY_DIRECTORY}")

#
# CTEST_CMAKE_GENERATOR:
#

# Query Generator from build directory (if possible):
IF(EXISTS ${CTEST_BINARY_DIRECTORY}/CMakeCache.txt)
  FILE(STRINGS ${CTEST_BINARY_DIRECTORY}/CMakeCache.txt _generator
    REGEX "^CMAKE_GENERATOR:"
    )
  STRING(REGEX REPLACE "^.*=" "" _generator ${_generator})
ENDIF()

IF("${CTEST_CMAKE_GENERATOR}" STREQUAL "")
  IF(NOT "${_generator}" STREQUAL "")
    SET(CTEST_CMAKE_GENERATOR ${_generator})
  ELSE()
    # default to "Unix Makefiles"
    SET(CTEST_CMAKE_GENERATOR "Unix Makefiles")
  ENDIF()
ELSE()
  # ensure that CTEST_CMAKE_GENERATOR (that was apparently set) is
  # compatible with the build directory:
  IF( NOT "${CTEST_CMAKE_GENERATOR}" STREQUAL "${_generator}"
      AND NOT "${_generator}" STREQUAL "" )
    MESSAGE(FATAL_ERROR "
The build directory is already set up with Generator \"${_generator}\", but
CTEST_CMAKE_GENERATOR was set to a different Generator \"${CTEST_CMAKE_GENERATOR}\".
"
     )
  ENDIF()
ENDIF()

MESSAGE("-- CTEST_CMAKE_GENERATOR:  ${CTEST_CMAKE_GENERATOR}")

#
# CTEST_SITE:
#

IF("${CTEST_SITE}" STREQUAL "")
  FIND_PROGRAM(HOSTNAME_COMMAND NAMES hostname)
  IF(NOT "${HOSTNAME_COMMAND}" MATCHES "-NOTFOUND")
    EXEC_PROGRAM(${HOSTNAME_COMMAND} OUTPUT_VARIABLE _hostname)
    STRING(REGEX REPLACE "\\..*$" "" _hostname ${_hostname})
    SET(CTEST_SITE "${_hostname}")
  ELSE()
    # Well, no hostname available. What about:
    SET(CTEST_SITE "BobMorane")
  ENDIF()
ENDIF()

MESSAGE("-- CTEST_SITE:             ${CTEST_SITE}")

IF(TRACK MATCHES "^Regression Tests$" AND NOT CTEST_SITE MATCHES "^tester$")
  MESSAGE(FATAL_ERROR "
I'm sorry ${CTEST_SITE}, I'm afraid I can't do that.
The TRACK \"Regression Tests\" is not for you.
"
    )
ENDIF()

#
# Assemble configuration options, we need it now:
#

IF("${MAKEOPTS}" STREQUAL "")
  SET(MAKEOPTS $ENV{MAKEOPTS})
ENDIF()

IF(NOT "${CONFIG_FILE}" STREQUAL "")
  SET(_options "-C${CONFIG_FILE}")
ENDIF()

IF("${TRACK}" STREQUAL "Build Tests")
  SET(TEST_PICKUP_REGEX "^do_not_run_any_tests")
ENDIF()

# Pass all relevant variables down to configure:
GET_CMAKE_PROPERTY(_variables VARIABLES)
FOREACH(_var ${_variables})
  IF( _var MATCHES "^(ENABLE|TEST|TESTING|DEAL_II|ALLOW|WITH|FORCE|COMPONENT)_" OR
      _var MATCHES "^(DOCUMENTATION|EXAMPLES)" OR
      _var MATCHES "^(ADOLC|ARBORX|ARPACK|BOOST|OPENCASCADE|MUPARSER|HDF5|KOKKOS|METIS|MPI)_" OR
      _var MATCHES "^(GINKGO|P4EST|PETSC|SCALAPACK|SLEPC|THREADS|TBB|TRILINOS)_" OR
      _var MATCHES "^(UMFPACK|ZLIB|LAPACK|MUPARSER|CUDA)_" OR
      _var MATCHES "^(CMAKE|DEAL_II)_(C|CXX|Fortran|BUILD)_(COMPILER|FLAGS)" OR
      _var MATCHES "^CMAKE_BUILD_TYPE$" OR
      _var MATCHES "MAKEOPTS" OR
      ( NOT _var MATCHES "^[_]*CMAKE" AND _var MATCHES "_DIR$" ) )
    LIST(APPEND _options "-D${_var}=${${_var}}")
  ENDIF()
ENDFOREACH()

IF(COVERAGE)
  LIST(APPEND _options "-DDEAL_II_SETUP_COVERAGE=TRUE")
  LIST(APPEND _options "-DCMAKE_BUILD_TYPE=Debug")
ENDIF()

#
# CTEST_BUILD_NAME:
#

# Append compiler information to CTEST_BUILD_NAME:
IF(NOT EXISTS ${CTEST_BINARY_DIRECTORY}/detailed.log)
  # Apparently, ${CTEST_BINARY_DIRECTORY} is not a configured build
  # directory. In this case we need a trick: set up a dummy project and
  # query it for the compiler information.
  FILE(WRITE ${CTEST_BINARY_DIRECTORY}/query_for_compiler/CMakeLists.txt "
FILE(WRITE ${CTEST_BINARY_DIRECTORY}/detailed.log
  \"#        CMAKE_CXX_COMPILER:     \${CMAKE_CXX_COMPILER_ID} \${CMAKE_CXX_COMPILER_VERSION} on platform \${CMAKE_SYSTEM_NAME} \${CMAKE_SYSTEM_PROCESSOR}\"
  )"
    )
  EXECUTE_PROCESS(
    COMMAND ${CMAKE_COMMAND} ${_options} "-G${CTEST_CMAKE_GENERATOR}" .
    OUTPUT_QUIET ERROR_QUIET
    WORKING_DIRECTORY ${CTEST_BINARY_DIRECTORY}/query_for_compiler
    )
  FILE(REMOVE_RECURSE ${CTEST_BINARY_DIRECTORY}/query_for_compiler)
ENDIF()

IF(EXISTS ${CTEST_BINARY_DIRECTORY}/detailed.log)
  FILE(STRINGS ${CTEST_BINARY_DIRECTORY}/detailed.log _compiler_id
    REGEX "CMAKE_CXX_COMPILER:"
    )
  STRING(REGEX REPLACE
    "^.*CMAKE_CXX_COMPILER:     \(.*\) on platform.*$" "\\1"
    _compiler_id ${_compiler_id}
    )
  STRING(REGEX REPLACE "^\(.*\) .*$" "\\1" _compiler_name ${_compiler_id})
  STRING(REGEX REPLACE "^.* " "" _compiler_version ${_compiler_id})
  STRING(REGEX REPLACE " " "-" _compiler_id ${_compiler_id})
  IF( NOT "${_compiler_id}" STREQUAL "" OR
      _compiler_id MATCHES "CMAKE_CXX_COMPILER" )
    SET(CTEST_BUILD_NAME "${_compiler_id}")
  ENDIF()
ENDIF()

#
# Query git information:
#

FIND_PACKAGE(Git)

IF(NOT GIT_FOUND)
  MESSAGE(FATAL_ERROR "\nCould not find git. Bailing out.\n"
   )
ENDIF()

EXECUTE_PROCESS(
   COMMAND ${GIT_EXECUTABLE} log -n 1 --pretty=format:"%h"
   WORKING_DIRECTORY ${CTEST_SOURCE_DIRECTORY}
   OUTPUT_VARIABLE _git_WC_INFO
   RESULT_VARIABLE _result
   OUTPUT_STRIP_TRAILING_WHITESPACE
   )

IF(NOT ${_result} EQUAL 0)
  MESSAGE(FATAL_ERROR "\nCould not retrieve git information. Bailing out.\n")
ENDIF()

STRING(REGEX REPLACE "^\"([^ ]+)\""
         "\\1" _git_WC_SHORTREV "${_git_WC_INFO}")

EXECUTE_PROCESS(
   COMMAND ${GIT_EXECUTABLE} symbolic-ref HEAD
   WORKING_DIRECTORY ${CTEST_SOURCE_DIRECTORY}
   OUTPUT_VARIABLE _git_WC_BRANCH
   RESULT_VARIABLE _result
   OUTPUT_STRIP_TRAILING_WHITESPACE
   )

STRING(REGEX REPLACE "refs/heads/" ""
  _git_WC_BRANCH "${_git_WC_BRANCH}")

IF(NOT "${_git_WC_BRANCH}" STREQUAL "")
  SET(CTEST_BUILD_NAME "${CTEST_BUILD_NAME}-${_git_WC_BRANCH}")
ENDIF()

#
# Append config file name to CTEST_BUILD_NAME:
#

IF(NOT "${CONFIG_FILE}" STREQUAL "")
  GET_FILENAME_COMPONENT(_conf ${CONFIG_FILE} NAME_WE)
  STRING(REGEX REPLACE "#.*$" "" _conf ${_conf})
  SET(CTEST_BUILD_NAME "${CTEST_BUILD_NAME}-${_conf}")
ENDIF()

#
# Append DESCRIPTION string to CTEST_BUILD_NAME:
#

IF(NOT "${DESCRIPTION}" STREQUAL "")
  SET(CTEST_BUILD_NAME "${CTEST_BUILD_NAME}-${DESCRIPTION}")
ENDIF()

MESSAGE("-- CTEST_BUILD_NAME:       ${CTEST_BUILD_NAME}")

#
# Declare files that should be submitted as notes:
#

SET(CTEST_NOTES_FILES
  ${CTEST_BINARY_DIRECTORY}/revision.log
  ${CTEST_BINARY_DIRECTORY}/summary.log
  ${CTEST_BINARY_DIRECTORY}/detailed.log
  ${CTEST_BINARY_DIRECTORY}/include/deal.II/base/config.h
  )

#
# Setup coverage:
#

IF(COVERAGE)
  IF(NOT TRACK MATCHES "Experimental")
    MESSAGE(FATAL_ERROR "
TRACK must be set to  \"Experimental\" if Coverage is enabled via
COVERAGE=TRUE.
"
      )
  ENDIF()

  IF(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    FIND_PROGRAM(GCOV_COMMAND NAMES llvm-cov)
    SET(GCOV_COMMAND "${GCOV_COMMAND} gcov")
    IF(GCOV_COMMAND MATCHES "-NOTFOUND")
      MESSAGE(FATAL_ERROR "Coverage enabled but could not find the
                           llvm-cov executable, which is part of LLVM.")
    ENDIF()
  ELSE()
    FIND_PROGRAM(GCOV_COMMAND NAMES gcov)
    IF(GCOV_COMMAND MATCHES "-NOTFOUND")
      MESSAGE(FATAL_ERROR "Coverage enabled but could not find the
                           gcov executable, which is part of the
                           GNU Compiler Collection.")
    ENDIF()
  ENDIF()

  SET(CTEST_COVERAGE_COMMAND "${GCOV_COMMAND}")
ENDIF()

MESSAGE("-- COVERAGE:               ${COVERAGE}")


#
# Setup memcheck:
#

IF(MEMORYCHECK)
  IF(NOT TRACK MATCHES "Experimental")
    MESSAGE(FATAL_ERROR "
TRACK must be set to  \"Experimental\" if Memcheck is enabled via
MEMORYCHECK=TRUE.
"
      )
  ENDIF()

  FIND_PROGRAM(MEMORYCHECK_COMMAND NAMES valgrind)
  IF(MEMORYCOMMAND MATCHES "-NOTFOUND")
    MESSAGE(FATAL_ERROR "
Memcheck enabled but could not find the valgrind executable. Please install
valgrind.
"
       )
  ENDIF()

  SET(CTEST_MEMORYCHECK_COMMAND "${MEMORYCHECK_COMMAND}")
ENDIF()

MESSAGE("-- MEMORYCHECK:               ${MEMORYCHECK}")



MACRO(CREATE_TARGETDIRECTORIES_TXT)
  #
  # It gets tricky: Fake a TargetDirectories.txt containing _all_ target
  # directories (of the main project and all subprojects) so that the
  # CTEST_COVERAGE() actually picks everything up...
  #
  EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy
    ${CTEST_BINARY_DIRECTORY}/CMakeFiles/TargetDirectories.txt
    ${CTEST_BINARY_DIRECTORY}/CMakeFiles/TargetDirectories.txt.bck
    )
  FILE(GLOB _subprojects ${CTEST_BINARY_DIRECTORY}/tests/*)
  FOREACH(_subproject ${_subprojects})
    IF(EXISTS ${_subproject}/CMakeFiles/TargetDirectories.txt)
      FILE(READ ${_subproject}/CMakeFiles/TargetDirectories.txt _var)
      FILE(APPEND ${CTEST_BINARY_DIRECTORY}/CMakeFiles/TargetDirectories.txt ${_var})
    ENDIF()
  ENDFOREACH()
ENDMACRO()

MACRO(CLEAR_TARGETDIRECTORIES_TXT)
  EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E rename
    ${CTEST_BINARY_DIRECTORY}/CMakeFiles/TargetDirectories.txt.bck
    ${CTEST_BINARY_DIRECTORY}/CMakeFiles/TargetDirectories.txt
    )
ENDMACRO()

MESSAGE("-- CMake Options:          ${_options}")

IF(NOT "${MAKEOPTS}" STREQUAL "")
  MESSAGE("-- MAKEOPTS:               ${MAKEOPTS}")
ENDIF()


########################################################################
#                                                                      #
#                          Run the testsuite:                          #
#                                                                      #
########################################################################

CTEST_START(Experimental TRACK ${TRACK})

MESSAGE("-- Running CTEST_UPDATE() to query git information")
CTEST_UPDATE(SOURCE ${CTEST_SOURCE_DIRECTORY})

MESSAGE("-- Running CTEST_CONFIGURE()")
CTEST_CONFIGURE(OPTIONS "${_options}" RETURN_VALUE _res)

IF("${_res}" STREQUAL "0")
  # Only run the build stage if configure was successful:

  MESSAGE("-- Running CTEST_BUILD()")
  SET(CTEST_BUILD_FLAGS "${MAKEOPTS}")
  CTEST_BUILD(NUMBER_ERRORS _res)

  IF("${_res}" STREQUAL "0")
    # Only run tests if the build was successful:

    IF(ENABLE_PERFORMANCE_TESTS)
      MESSAGE("-- Running prune_tests")
      EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND}
        --build . --target prune_tests
        -- ${MAKEOPTS}
        WORKING_DIRECTORY ${CTEST_BINARY_DIRECTORY}
        OUTPUT_QUIET
        RESULT_VARIABLE _res
        )

      IF(NOT "${_res}" STREQUAL "0")
        MESSAGE(FATAL_ERROR "
\"prune_tests\" target exited with an error. Bailing out.
"
          )
      ENDIF()

      SET(_target setup_tests_performance)
    ELSE()
      SET(_target setup_tests)
    ENDIF()

    MESSAGE("-- Running ${_target}")
    EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND}
      --build . --target ${_target}
      -- ${MAKEOPTS}
      WORKING_DIRECTORY ${CTEST_BINARY_DIRECTORY}
      OUTPUT_QUIET
      RESULT_VARIABLE _res
      )

    IF(NOT "${_res}" STREQUAL "0")
      MESSAGE(FATAL_ERROR "
\"setup_tests\" target exited with an error. Bailing out.
"
        )
    ENDIF()

    IF(DEAL_II_MSVC)
      SET(CTEST_BUILD_CONFIGURATION "${JOB_BUILD_CONFIGURATION}")
    ENDIF()
    IF(MEMORYCHECK)
      MESSAGE("-- Running CTEST_MEMCHECK()")
      CTEST_MEMCHECK()
    ELSE()
      MESSAGE("-- Running CTEST_TESTS()")
      CTEST_TEST()
    ENDIF(MEMORYCHECK)

    IF(COVERAGE)
      CREATE_TARGETDIRECTORIES_TXT()
      MESSAGE("-- Running CTEST_COVERAGE()")
      CTEST_COVERAGE()
      SET (CODE_COV_BASH "${CMAKE_CURRENT_LIST_DIR}/../contrib/utilities/programs/codecov/codecov-bash.sh")
      IF (EXISTS ${CODE_COV_BASH})
        MESSAGE("-- Running codecov-bash")
        EXECUTE_PROCESS(COMMAND bash "${CODE_COV_BASH}"
                                     "-t ac85e7ce-5316-4bc1-a237-2fe724028c7b" "-x '${GCOV_COMMAND}'"
                        OUTPUT_QUIET)
      ENDIF()
      CLEAR_TARGETDIRECTORIES_TXT()
    ENDIF(COVERAGE)

  ENDIF()
ENDIF()

#
# Inject compiler information and svn revision into xml files:
#

FILE(STRINGS ${CTEST_BINARY_DIRECTORY}/Testing/TAG _tag LIMIT_COUNT 1)
SET(_path "${CTEST_BINARY_DIRECTORY}/Testing/${_tag}")
IF(NOT EXISTS ${_path})
  MESSAGE(FATAL_ERROR "
Unable to determine test submission files from TAG. Bailing out.
"
    )
ENDIF()

#
# Create performance test report
#
IF(ENABLE_PERFORMANCE_TESTS)
  MESSAGE("-- Collecting performance measurements\n")
  EXECUTE_PROCESS(
    COMMAND bash "${CMAKE_CURRENT_LIST_DIR}/performance/collect_measurements" "${CTEST_SITE}"
    WORKING_DIRECTORY ${CTEST_BINARY_DIRECTORY}
    )
ENDIF()


#
# And finally submit:
#

IF(NOT SKIP_SUBMISSION)
  MESSAGE("-- Running CTEST_SUBMIT()")
  CTEST_SUBMIT(RETURN_VALUE _res)

  IF("${_res}" STREQUAL "0")
    MESSAGE("-- Submission successful. Goodbye!")
  ENDIF()
ENDIF()

# .oO( This script is freaky 606 lines long... )
