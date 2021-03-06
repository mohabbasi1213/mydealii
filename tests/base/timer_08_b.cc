// ---------------------------------------------------------------------
//
// Copyright (C) 2018 - 2021 by the deal.II authors
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


// test TimerOutput with standard section names

#include <deal.II/base/timer.h>

#include <algorithm>
#include <sstream>

#include "../tests.h"

// burn computer time
double s = 0.;
void
burn(unsigned int n)
{
  for (unsigned int i = 0; i < n; ++i)
    {
      for (unsigned int j = 1; j < 100000; ++j)
        {
          s += 1. / j * i;
        }
    }
}

void
test(TimerOutput::OutputType output_type)
{
  std::stringstream ss;
  {
    TimerOutput t(ss, TimerOutput::summary, output_type);

    t.enter_subsection("Hello? Hello? Hello?");
    burn(50);
    t.leave_subsection("Hello? Hello? Hello?");

    t.enter_subsection("Is there anybody in there?");
    burn(50);
    t.leave_subsection("Is there anybody in there?");
  }

  std::string s = ss.str();
  std::replace_if(s.begin(), s.end(), ::isdigit, ' ');
  std::replace_if(
    s.begin(), s.end(), [](char x) { return x == '.'; }, ' ');
  deallog << s << std::endl << std::endl;
}

int
main()
{
  initlog();

  deallog << "cpu_times:" << std::endl;
  test(TimerOutput::cpu_times);
  deallog << "wall_times:" << std::endl;
  test(TimerOutput::wall_times);
  deallog << "cpu_and_wall_times:" << std::endl;
  test(TimerOutput::cpu_and_wall_times);
  deallog << "cpu_and_wall_times_grouped:" << std::endl;
  test(TimerOutput::cpu_and_wall_times_grouped);
}
