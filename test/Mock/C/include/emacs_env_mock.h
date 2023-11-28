#include "emacs_module.h"

struct emacs_env_private {
  void *owner;
};

struct emacs_value_tag {
  void *data;
};
