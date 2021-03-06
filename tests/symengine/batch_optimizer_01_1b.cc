// ---------------------------------------------------------------------
//
// Copyright (C) 2020 - 2021 by the deal.II authors
//
// This file is part of the deal.II library.
//
// The deal.II library is free software; you can use it, redistribute
// it, and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// The full text of the license can be found in the file LICENSE at
// the top level of the deal.II distribution.
//
// ---------------------------------------------------------------------


// Test that all of the low-level math operations function as expected
// and that their values and derivatives can be computed using the
// optimizer.
// For this test the optimizer uses plain old dictionary substitution,
// but all other optimizations (e.g. CSE) have been enabled.
// This test is based on function_verification_01.cc

#include "../tests.h"

#include "sd_common_tests/batch_optimizer_01.h"


int
main()
{
  initlog();
  deallog << std::setprecision(7);

  const enum SD::OptimizerType     opt_method = SD::OptimizerType::dictionary;
  const enum SD::OptimizationFlags opt_flags =
    SD::OptimizationFlags::optimize_all;

  run_tests<opt_method, opt_flags>();

  deallog << "OK" << std::endl;
}
