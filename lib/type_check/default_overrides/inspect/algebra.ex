defmodule TypeCheck.DefaultOverrides.Inspect.Algebra do
  use TypeCheck
  alias TypeCheck.DefaultOverrides.IO

  @typep! doc_break() :: {:doc_break, binary(), :flex | :strict}

  @typep! doc_collapse() :: {:doc_collapse, pos_integer()}

  @typep! doc_color() :: {:doc_color, t(), IO.ANSI.ansidata()}

  @typep! doc_cons() :: {:doc_cons, t(), t()}

  @typep! doc_fits() :: {:doc_fits, t(), :enabled | :disabled}

  @typep! doc_force() :: {:doc_force, t()}

  @typep! doc_group() :: {:doc_group, t(), :inherit | :self}

  @typep! doc_nest() ::
            {:doc_nest, t(), :cursor | :reset | non_neg_integer(), :always | :break}

  @typep! doc_string() :: {:doc_string, t(), non_neg_integer()}

  # @typep! mode() :: :flat | :flat_no_break | :break | :break_no_flat

  @type! t() ::
           binary()
           | :doc_line
           | :doc_nil
           | doc_break()
           | doc_collapse()
           | doc_color()
           | doc_cons()
           | doc_fits()
           | doc_force()
           | doc_group()
           | doc_nest()
           | doc_string()
end
