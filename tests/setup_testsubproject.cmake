FIND_PACKAGE(deal.II 9.2.0 REQUIRED HINTS ${DEAL_II_DIR})

SET(CMAKE_BUILD_TYPE ${DEAL_II_BUILD_TYPE} CACHE STRING "" FORCE)
DEAL_II_INITIALIZE_CACHED_VARIABLES()

FOREACH(_var
    DIFF_DIR NUMDIFF_DIR TEST_PICKUP_REGEX TEST_TIME_LIMIT
    TEST_MPI_RANK_LIMIT TEST_THREAD_LIMIT ENABLE_PERFORMANCE_TESTS
    TESTING_ENVIRONMENT
    )
  SET_IF_EMPTY(${_var} "$ENV{${_var}}")
  SET(${_var} "${${_var}}" CACHE STRING "" FORCE)
ENDFOREACH()

IF(DEAL_II_WITH_CUDA)
  PROJECT(TESTSUITE CXX CUDA)
ENDIF()

#
# A custom target that does absolutely nothing. It is used in the main
# project to trigger a "make rebuild_cache" if necessary.
#
ADD_CUSTOM_TARGET(regenerate)
