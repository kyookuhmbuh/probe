
#include <iostream>

#include <example.hpp>

int main()
{
  std::cout << "target_link_libraries check " << test_add(2, 4) << "\n";

#ifdef MY_CUSTOM_FEATURE
  std::cout << "load_target_config check \n";
#endif

  return 0;
}
