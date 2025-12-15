# Complete Guide to Semantic Analysis in the Compiler

## Table of Contents
1. [Introduction to Semantic Analysis](#introduction)
2. [Architecture Overview](#architecture)
3. [Symbol Table System](#symbol-table)
4. [Scope Management](#scope-management)
5. [Variable Declaration Analysis](#variable-declaration)
6. [Array Declaration and Usage](#array-declaration)
7. [Type System and Propagation](#type-system)
8. [Assignment Type Checking](#assignment-checking)
9. [Operator Type Checking](#operator-checking)
10. [Function Analysis](#function-analysis)
11. [Error Detection and Reporting](#error-reporting)
12. [Complete Walkthrough Examples](#walkthrough)
13. [Implementation Details](#implementation)

---

## <a name="introduction"></a>1. Introduction to Semantic Analysis

### What is Semantic Analysis?

Semantic analysis is the third phase of compilation (after lexical analysis and syntax analysis). While syntax analysis checks if code follows grammar rules, semantic analysis checks if the code makes **logical sense**.

### Key Responsibilities

1. **Type Checking**: Ensures types are used correctly
2. **Scope Analysis**: Manages variable visibility and lifetime
3. **Symbol Management**: Tracks all identifiers (variables, functions, arrays)
4. **Error Detection**: Finds semantic errors without stopping compilation
5. **Type Propagation**: Tracks types through expressions

### Example: Syntax vs Semantic

```c
// Syntax Error (caught by parser)
int x = ;  // Missing value

// Semantic Error (caught by semantic analyzer)
int x;
int x;  // Duplicate declaration
```

---

## <a name="architecture"></a>2. Architecture Overview

### Core Components

```
┌─────────────────────────────────────────┐
│         Semantic Analyzer                │
├─────────────────────────────────────────┤
│  1. Symbol Table Manager                │
│  2. Type System                          │
│  3. Scope Manager                        │
│  4. Error Collector                     │
│  5. Type Propagator                      │
└─────────────────────────────────────────┘
```

### Data Structures

```cpp
// Global symbol table
symbol_table *table;

// Current context tracking
string current_type;                    // Type being declared (int/float/void)
string current_func_name;               // Function being defined
string current_func_return_type;        // Return type of current function
vector<pair<string, string>> current_func_params;  // Function parameters

// Error tracking
int error_count = 0;                    // Total errors found
ofstream outlog;                        // Log file
ofstream errlog;                        // Error file
```

### Helper Functions

```cpp
// Check if function exists
bool is_function_declared(string name);

// Check if variable exists in current scope only
bool is_variable_declared_current_scope(string name);

// Get variable/function information
symbol_info* get_variable_info(string name);
```

---

## <a name="symbol-table"></a>3. Symbol Table System

### What is a Symbol Table?

A symbol table is a data structure that stores information about all identifiers (variables, functions, arrays) in the program. Think of it as a **phonebook** for your code.

### Symbol Information Stored

Each symbol stores:

```cpp
class symbol_info {
    string name;              // Identifier name (e.g., "x", "func")
    string type;             // Token type (e.g., "ID")
    string symbol_type;      // "variable", "array", or "function"
    string data_type;        // "int", "float", or "void"
    string return_type;      // For functions: return type
    vector<pair<string, string>> parameters;  // For functions: (type, name) pairs
    int array_size;          // For arrays: size
};
```

### Symbol Table Operations

#### Insertion

When a variable is declared:
```cpp
int x;
```

The code creates and inserts:
```cpp
symbol_info* new_var = new symbol_info("x", "ID");
new_var->set_symbol_type("variable");
new_var->set_data_type("int");
table->insert(new_var);
```

#### Lookup

When a variable is used:
```cpp
int y = x;
```

The code looks it up:
```cpp
symbol_info* var_info = get_variable_info("x");
if (var_info == NULL) {
    // Error: Variable not found
}
```

### Symbol Table Structure

The symbol table uses a **hash table** with **chaining** to handle collisions:

```
Scope 1 (Global)
├── Hash Bucket 0: [x, y, z]
├── Hash Bucket 1: [func1, func2]
└── Hash Bucket 2: [arr1]

Scope 2 (Inside function)
├── Hash Bucket 0: [local_var]
└── Hash Bucket 1: [temp]
```

---

## <a name="scope-management"></a>4. Scope Management

### What is a Scope?

A scope is a region of code where variables are visible. In C, scopes are created by:
- Function bodies `{ }`
- Block statements `{ }`
- Global scope (outside all functions)

### Scope Rules

1. **Inner scopes can see outer scopes**
2. **Outer scopes cannot see inner scopes**
3. **Same name in inner scope shadows outer scope**

### Example

```c
int x = 10;        // Global scope

int main() {
    int x = 20;    // Local scope (shadows global x)
    {
        int x = 30; // Inner scope (shadows local x)
        // x here is 30
    }
    // x here is 20
}
// x here is 10
```

### Implementation

#### Entering a Scope

When parser sees `{`:
```cpp
compound_statement : LCURL {
    table->enter_scope();  // Create new scope
    // ... add function parameters if in function ...
} statements RCURL {
    table->exit_scope();   // Remove scope
}
```

#### Scope Stack

The symbol table maintains a **stack of scopes**:

```
Stack (top to bottom):
┌─────────────┐
│ Scope 3     │ ← Current scope (most recent)
├─────────────┤
│ Scope 2     │
├─────────────┤
│ Scope 1     │ ← Global scope
└─────────────┘
```

#### Lookup Strategy

When looking up a variable:
1. Check current scope first
2. If not found, check parent scope
3. Continue up the scope chain
4. If not found in any scope → Error

#### Exiting a Scope

When parser sees `}`:
```cpp
table->print_current_scope();  // Print variables in this scope
table->exit_scope();            // Remove scope from stack
```

All variables in that scope are automatically removed.

---

## <a name="variable-declaration"></a>5. Variable Declaration Analysis

### Declaration Process

When the parser encounters:
```c
int x, y, z;
```

The following happens:

#### Step 1: Type Specification

```cpp
type_specifier : INT {
    $$ = new symbol_info("int", "type");
    current_type = "int";  // Store for later use
}
```

#### Step 2: Process Each Variable

For each variable in the declaration list:

```cpp
declaration_list : declaration_list COMMA ID {
    // Check if variable already exists in current scope
    if(is_variable_declared_current_scope($3->getname())) {
        // ERROR: Duplicate declaration
        errlog << "Multiple declaration of variable " << $3->getname() << endl;
        error_count++;
    } else {
        // Create new variable entry
        symbol_info* new_var = new symbol_info($3->getname(), "ID");
        new_var->set_symbol_type("variable");
        new_var->set_data_type(current_type);  // Use stored type
        table->insert(new_var);  // Add to symbol table
    }
}
```

### Declaration Checks

#### Check 1: Duplicate Declaration

**Rule**: A variable cannot be declared twice in the same scope.

**Example**:
```c
int x;
int x;  // Error: Multiple declaration
```

**Code**:
```cpp
if(is_variable_declared_current_scope($3->getname())) {
    errlog << "Multiple declaration of variable " << $3->getname() << endl;
    error_count++;
}
```

**Why**: Prevents confusion about which variable is being used.

#### Check 2: Void Variables Not Allowed

**Rule**: Variables cannot have type `void`.

**Example**:
```c
void x;  // Error: variable type can not be void
```

**Code**:
```cpp
if (current_type == "void") {
    errlog << "variable type can not be void" << endl;
    error_count++;
}
```

**Why**: `void` means "no type", which doesn't make sense for variables.

### Variable Information Storage

When a variable is successfully declared:

```cpp
symbol_info {
    name: "x"
    symbol_type: "variable"
    data_type: "int"
    // Other fields set to defaults
}
```

This information is used later for:
- Type checking in assignments
- Type checking in expressions
- Error messages

---

## <a name="array-declaration"></a>6. Array Declaration and Usage

### Array Declaration

When the parser encounters:
```c
int arr[10];
```

#### Declaration Process

```cpp
declaration_list : ID LTHIRD CONST_INT RTHIRD {
    // Check for duplicate
    if(is_variable_declared_current_scope($1->getname())) {
        errlog << "Multiple declaration of variable " << $1->getname() << endl;
        error_count++;
    } else {
        // Create array entry
        int size = stoi($3->getname());  // Convert "10" to 10
        symbol_info* new_array = new symbol_info($1->getname(), "ID");
        new_array->set_symbol_type("array");      // Mark as array
        new_array->set_data_type(current_type);    // Element type (int)
        new_array->set_array_size(size);           // Size (10)
        table->insert(new_array);
    }
}
```

#### Array Information Stored

```cpp
symbol_info {
    name: "arr"
    symbol_type: "array"      // Different from "variable"
    data_type: "int"          // Type of elements
    array_size: 10           // Number of elements
}
```

### Array Usage Checks

#### Check 1: Array Used Without Index

**Rule**: Arrays must be accessed with an index `[i]`.

**Example**:
```c
int arr[10];
int x = arr;  // Error: variable is of array type
```

**Code**:
```cpp
variable : ID {
    symbol_info* var_info = get_variable_info($1->getname());
    
    if (var_info != NULL && var_info->get_symbol_type() == "array") {
        errlog << "variable is of array type : " << $1->getname() << endl;
        error_count++;
    }
}
```

**Why**: Arrays are collections; you must specify which element.

#### Check 2: Non-Array Used With Index

**Rule**: Only arrays can use index notation.

**Example**:
```c
int x;
int y = x[5];  // Error: variable is not of array type
```

**Code**:
```cpp
variable : ID LTHIRD expression RTHIRD {
    symbol_info* var_info = get_variable_info($1->getname());
    
    if (var_info != NULL) {
        if (var_info->get_symbol_type() != "array") {
            errlog << "variable is not of array type : " << $1->getname() << endl;
            error_count++;
        }
    }
}
```

**Why**: Regular variables are single values, not collections.

#### Check 3: Array Index Must Be Integer

**Rule**: Array indices must be integer expressions.

**Example**:
```c
int arr[10];
arr[2.5] = 5;  // Error: array index is not of integer type
```

**Code**:
```cpp
variable : ID LTHIRD expression RTHIRD {
    // Check index type
    if ($3->get_data_type() != "int") {
        errlog << "array index is not of integer type : " << $1->getname() << endl;
        error_count++;
    }
}
```

**Why**: Array indices represent positions (0, 1, 2, ...), which are integers.

### Array Access Type

When accessing an array element:
```c
int arr[10];
int x = arr[5];
```

The type of `arr[5]` is the **element type** of the array:
- `arr` is `int[10]` (array of int)
- `arr[5]` is `int` (single element)

This is handled by:
```cpp
$$->set_data_type(var_info->get_data_type());  // Element type
```

---

## <a name="type-system"></a>7. Type System and Propagation

### Type System Overview

The compiler supports three basic types:
- `int`: Integer numbers (5, -10, 0)
- `float`: Floating-point numbers (3.14, 2.5)
- `void`: No type (for functions that don't return values)

### Type Storage

Every expression has a **data type** attached:

```cpp
symbol_info {
    name: "5 + 3"
    data_type: "int"  // Result type
}
```

### Type Propagation

Type propagation means **tracking the type of an expression as it's built**.

#### Example: Simple Expression

```c
int x = 5 + 3;
```

**Step-by-step**:
1. `5` → type: `int`
2. `3` → type: `int`
3. `5 + 3` → type: `int` (both operands are int)

#### Example: Mixed Types

```c
int x = 5 * 3.14;
```

**Step-by-step**:
1. `5` → type: `int`
2. `3.14` → type: `float`
3. `5 * 3.14` → type: `float` (if either operand is float, result is float)

### Type Propagation Rules

#### Addition/Subtraction

```cpp
simple_expression : simple_expression ADDOP term {
    // If either operand is float, result is float
    if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
        $$->set_data_type("float");
    } 
    // If both are int, result is int
    else if ($1->get_data_type() == "int" && $3->get_data_type() == "int") {
        $$->set_data_type("int");
    }
}
```

**Rules**:
- `int + int` → `int`
- `int + float` → `float`
- `float + int` → `float`
- `float + float` → `float`

#### Multiplication/Division

```cpp
term : term MULOP unary_expression {
    if ($2->getname() == "*" || $2->getname() == "/") {
        if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
            $$->set_data_type("float");
        } else if ($1->get_data_type() == "int" && $3->get_data_type() == "int") {
            $$->set_data_type("int");
        }
    }
}
```

**Rules**:
- `int * int` → `int`
- `int * float` → `float`
- `float / int` → `float`

#### Relational Operators

```cpp
rel_expression : simple_expression RELOP simple_expression {
    $$->set_data_type("int");  // Always integer (0 or 1)
}
```

**Rule**: Relational operators (`<`, `>`, `==`, etc.) always return `int`:
- `5 > 3` → `1` (true)
- `2 < 1` → `0` (false)

#### Logical Operators

```cpp
logic_expression : rel_expression LOGICOP rel_expression {
    $$->set_data_type("int");  // Always integer (0 or 1)
}
```

**Rule**: Logical operators (`&&`, `||`) always return `int`.

### Type Propagation Through Expressions

Complex expression example:
```c
int x = 2 + 3 * 4.5;
```

**Type propagation**:
1. `4.5` → `float`
2. `3` → `int`
3. `3 * 4.5` → `float` (int * float = float)
4. `2` → `int`
5. `2 + (float)` → `float` (int + float = float)
6. `x = float` → Warning (int = float)

---

## <a name="assignment-checking"></a>8. Assignment Type Checking

### Assignment Rule

When you write:
```c
variable = expression;
```

The compiler checks:
1. Is the variable declared?
2. Is the expression type compatible?
3. Is the expression void?

### Assignment Process

```cpp
expression : variable ASSIGNOP logic_expression {
    // Check 1: Void function result
    if ($3->get_data_type() == "void") {
        errlog << "operation on void type" << endl;
        error_count++;
    }
    // Check 2: Type compatibility
    else if ($1->get_data_type() != $3->get_data_type()) {
        // Special case: float to int (warning)
        if ($3->get_data_type() == "float" && $1->get_data_type() == "int") {
            errlog << "Warning: Assignment of float value into variable of integer type" << endl;
        } else {
            // Other mismatches (error)
            errlog << "Type mismatch in assignment" << endl;
        }
        error_count++;
    }
}
```

### Assignment Checks

#### Check 1: Void Function Result

**Rule**: Cannot assign result of void function.

**Example**:
```c
void func() { }
int x = func();  // Error: operation on void type
```

**Why**: Void functions don't return values.

#### Check 2: Type Compatibility

**Rule**: Assignment types should match (with special case for float→int).

**Example 1: Matching Types**
```c
int x;
x = 5;  // OK: int = int
```

**Example 2: Float to Int (Warning)**
```c
int x;
float y = 3.14;
x = y;  // Warning: Assignment of float value into variable of integer type
```

**Why**: Information may be lost (3.14 → 3).

**Example 3: Other Mismatches (Error)**
```c
int x;
void y;
x = y;  // Error: Type mismatch
```

### Type Conversion Rules

The compiler handles one implicit conversion:
- `float` → `int`: Warning (data loss possible)

All other mismatches are errors.

---

## <a name="operator-checking"></a>9. Operator Type Checking

### Modulus Operator (`%`)

#### Check 1: Both Operands Must Be Integer

**Rule**: Modulus requires integer operands.

**Example**:
```c
int x = 5 % 3.5;  // Error: Modulus operator on non integer type
```

**Code**:
```cpp
if ($2->getname() == "%") {
    if ($1->get_data_type() != "int" || $3->get_data_type() != "int") {
        errlog << "Modulus operator on non integer type" << endl;
        error_count++;
    } else {
        $$->set_data_type("int");  // Result is always int
    }
}
```

**Why**: Modulus is remainder after integer division.

#### Check 2: Modulus by Zero

**Rule**: Cannot divide by zero.

**Example**:
```c
int x = 5 % 0;  // Error: Modulus by 0
```

**Code**:
```cpp
if ($2->getname() == "%") {
    if ($3->getname() == "0") {
        errlog << "Modulus by 0" << endl;
        error_count++;
    }
}
```

**Why**: Division by zero is undefined.

### Division Operator (`/`)

#### Check: Division by Zero

**Rule**: Cannot divide by zero.

**Example**:
```c
int x = 10 / 0;  // Error: Division by 0
```

**Code**:
```cpp
if ($2->getname() == "/") {
    if ($3->getname() == "0") {
        errlog << "Division by 0" << endl;
        error_count++;
    }
}
```

**Why**: Division by zero is undefined.

### Type Propagation for Operators

Operators also propagate types:

```cpp
// Multiplication/Division
if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
    $$->set_data_type("float");
} else {
    $$->set_data_type("int");
}

// Modulus (always int)
if ($2->getname() == "%") {
    $$->set_data_type("int");
}
```

---

## <a name="function-analysis"></a>10. Function Analysis

### Function Declaration

When you declare a function:
```c
int add(int a, float b) {
    return a + 3;
}
```

#### Step 1: Store Function Information

```cpp
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
    // Create function symbol
    symbol_info* func = new symbol_info($2->getname(), "ID");
    func->set_symbol_type("function");
    func->set_return_type($1->getname());  // "int"
    
    // Add parameters
    for(auto param : current_func_params) {
        func->add_parameter(param.first, param.second);  // (type, name)
    }
    
    table->insert(func);  // Store in symbol table
}
```

#### Step 2: Add Parameters to Function Scope

When entering function body:
```cpp
compound_statement : LCURL {
    table->enter_scope();  // New scope for function
    
    // Add parameters as variables in this scope
    for(auto param : current_func_params) {
        if(!param.second.empty()) {
            symbol_info* param_symbol = new symbol_info(param.second, "ID");
            param_symbol->set_symbol_type("variable");
            param_symbol->set_data_type(param.first);
            table->insert(param_symbol);
        }
    }
}
```

### Function Call Analysis

When you call a function:
```c
int result = add(5, 3.5);
```

#### Step 1: Collect Arguments

```cpp
arguments : arguments COMMA logic_expression {
    // Store argument type
    pair<string, string> param($3->getname(), $3->get_data_type());
    current_func_params.push_back(param);
}
```

#### Step 2: Function Call Checks

```cpp
factor : ID LPAREN argument_list RPAREN {
    symbol_info* func_info = get_variable_info($1->getname());
    
    // Check 1: Function exists
    if (func_info == NULL) {
        errlog << "Undeclared function: " << $1->getname() << endl;
        error_count++;
    }
    // Check 2: Is actually a function
    else if (func_info->get_symbol_type() != "function") {
        errlog << "A function call cannot be made with non-function type identifier" << endl;
        error_count++;
    }
    // Check 3: Parameter count matches
    else if (current_func_params.size() != func_info->get_parameters().size()) {
        errlog << "Inconsistencies in number of arguments in function call" << endl;
        error_count++;
    }
    // Check 4: Parameter types match
    else {
        for (int i = 0; i < current_func_params.size(); i++) {
            if (current_func_params[i].second != func_info->get_parameters()[i].first) {
                errlog << "argument " << (i+1) << " type mismatch in function call" << endl;
                error_count++;
            }
        }
    }
    
    // Set return type for expression
    $$->set_data_type(func_info->get_return_type());
}
```

### Function Call Checks

#### Check 1: Function Must Be Declared

**Rule**: Function must exist before use.

**Example**:
```c
foo();  // Error: Undeclared function: foo
```

**Code**:
```cpp
if (func_info == NULL) {
    errlog << "Undeclared function: " << $1->getname() << endl;
    error_count++;
}
```

#### Check 2: Must Be a Function

**Rule**: Identifier must be a function, not a variable.

**Example**:
```c
int x;
x();  // Error: A function call cannot be made with non-function type identifier
```

**Code**:
```cpp
if (func_info->get_symbol_type() != "function") {
    errlog << "A function call cannot be made with non-function type identifier" << endl;
    error_count++;
}
```

#### Check 3: Parameter Count Must Match

**Rule**: Number of arguments must match function definition.

**Example**:
```c
int add(int a, int b) { return a + b; }
add(5);        // Error: Need 2, got 1
add(5, 3, 7);  // Error: Need 2, got 3
```

**Code**:
```cpp
if (current_func_params.size() != func_info->get_parameters().size()) {
    errlog << "Inconsistencies in number of arguments in function call" << endl;
    error_count++;
}
```

#### Check 4: Parameter Types Must Match

**Rule**: Each argument type must match corresponding parameter type.

**Example**:
```c
int add(int a, float b) { return a + 3; }
add(5, 3.5);   // OK: int matches int, float matches float
add(5.5, 3);   // Error: float doesn't match int, int doesn't match float
```

**Code**:
```cpp
for (int i = 0; i < current_func_params.size(); i++) {
    if (current_func_params[i].second != func_info->get_parameters()[i].first) {
        errlog << "argument " << (i+1) << " type mismatch in function call" << endl;
        error_count++;
    }
}
```

#### Check 5: Void Function in Expression

**Rule**: Void functions cannot be used in expressions.

**Example 1: In Assignment**
```c
void func() { }
int x = func();  // Error: operation on void type
```

**Example 2: In Condition**
```c
void func() { }
if (func()) { }  // Error: A void function cannot be called as a part of an expression
```

**Code**:
```cpp
// In assignment
if ($3->get_data_type() == "void") {
    errlog << "operation on void type" << endl;
    error_count++;
}

// In IF/WHILE conditions
if ($3->get_data_type() == "void") {
    errlog << "A void function cannot be called as a part of an expression" << endl;
    error_count++;
}
```

---

## <a name="error-reporting"></a>11. Error Detection and Reporting

### Error Collection Strategy

The compiler uses a **non-stop error collection** approach:
- Errors are collected but don't stop compilation
- All errors are reported at the end
- Allows finding multiple errors in one pass

### Error Tracking

```cpp
int error_count = 0;        // Total errors found
ofstream errlog;            // Error output file
ofstream outlog;            // Log output file
```

### Error Types

#### 1. Declaration Errors
- Multiple declaration of variable
- Variable type cannot be void

#### 2. Usage Errors
- Undeclared variable
- Undeclared function

#### 3. Type Errors
- Type mismatch in assignment
- Assignment of float to int (warning)
- Operation on void type

#### 4. Array Errors
- Variable is of array type (used without index)
- Variable is not of array type (indexed but not array)
- Array index is not of integer type

#### 5. Function Errors
- Function call with non-function identifier
- Inconsistencies in number of arguments
- Argument type mismatch
- Void function in expression

#### 6. Operator Errors
- Modulus operator on non-integer type
- Modulus by 0
- Division by 0

### Error Reporting Format

All errors follow this format:
```
At line no: <line_number> <error_message>
```

**Example**:
```
At line no: 5 Multiple declaration of variable x
At line no: 10 Undeclared variable y
At line no: 15 Type mismatch in assignment: int and float
```

### Final Error Summary

At the end of compilation:
```cpp
errlog << "Total errors: " << error_count << endl;
outlog << "Total errors: " << error_count << endl;
```

---

## <a name="walkthrough"></a>12. Complete Walkthrough Examples

### Example 1: Simple Variable Declaration and Usage

**Code**:
```c
int main() {
    int x, y;
    float z;
    
    x = 5;
    y = x;
    z = 3.14;
    x = z;  // Warning
}
```

**Step-by-step Analysis**:

1. **Enter main scope**
   ```
   table->enter_scope()
   ```

2. **Declare `int x, y`**
   - Check "x" in current scope → Not found
   - Insert x: `{name: "x", type: "int", symbol_type: "variable"}`
   - Check "y" in current scope → Not found
   - Insert y: `{name: "y", type: "int", symbol_type: "variable"}`

3. **Declare `float z`**
   - Check "z" in current scope → Not found
   - Insert z: `{name: "z", type: "float", symbol_type: "variable"}`

4. **`x = 5`**
   - Lookup "x" → Found: `int`
   - Type of `5` → `int`
   - Types match → OK

5. **`y = x`**
   - Lookup "x" → Found: `int`
   - Lookup "y" → Found: `int`
   - Types match → OK

6. **`z = 3.14`**
   - Lookup "z" → Found: `float`
   - Type of `3.14` → `float`
   - Types match → OK

7. **`x = z`**
   - Lookup "x" → Found: `int`
   - Lookup "z" → Found: `float`
   - Types don't match → Warning
   - Error: "Warning: Assignment of float value into variable of integer type"

8. **Exit main scope**
   ```
   table->exit_scope()
   ```

### Example 2: Array Usage

**Code**:
```c
int main() {
    int arr[10];
    int x;
    
    arr[5] = 10;      // OK
    x = arr[3];       // OK
    arr[2.5] = 5;     // Error: index not integer
    x = arr;          // Error: array without index
    y[5] = 10;        // Error: y not array
}
```

**Step-by-step Analysis**:

1. **Declare `int arr[10]`**
   - Insert arr: `{name: "arr", type: "int", symbol_type: "array", size: 10}`

2. **Declare `int x`**
   - Insert x: `{name: "x", type: "int", symbol_type: "variable"}`

3. **`arr[5] = 10`**
   - Lookup "arr" → Found: `array`
   - Check index `5` → Type: `int` → OK
   - `arr[5]` type → `int` (element type)
   - `10` type → `int`
   - Types match → OK

4. **`x = arr[3]`**
   - Lookup "x" → Found: `int`
   - Lookup "arr" → Found: `array`
   - Check index `3` → Type: `int` → OK
   - `arr[3]` type → `int`
   - Types match → OK

5. **`arr[2.5] = 5`**
   - Lookup "arr" → Found: `array`
   - Check index `2.5` → Type: `float` → Error
   - Error: "array index is not of integer type : arr"

6. **`x = arr`**
   - Lookup "x" → Found: `int`
   - Lookup "arr" → Found: `array` → Error
   - Error: "variable is of array type : arr"

7. **`y[5] = 10`**
   - Lookup "y" → Not found → Error
   - Error: "Undeclared variable y"

### Example 3: Function Calls

**Code**:
```c
int add(int a, float b) {
    return a + 3;
}

int main() {
    add(5, 3.5);      // OK
    add(5);           // Error: wrong count
    add(5, 3.5, 7);   // Error: wrong count
    add(5.5, 3);      // Error: type mismatch
    foo();            // Error: undeclared
}
```

**Step-by-step Analysis**:

1. **Declare `int add(int a, float b)`**
   - Insert add: `{name: "add", symbol_type: "function", return_type: "int", params: [(int, a), (float, b)]}`

2. **`add(5, 3.5)`**
   - Lookup "add" → Found: `function`
   - Collect arguments: `[(5, int), (3.5, float)]`
   - Check count: 2 == 2 → OK
   - Check types: `int == int`, `float == float` → OK
   - Result type: `int`

3. **`add(5)`**
   - Collect arguments: `[(5, int)]`
   - Check count: 1 != 2 → Error
   - Error: "Inconsistencies in number of arguments in function call: add"

4. **`add(5, 3.5, 7)`**
   - Collect arguments: `[(5, int), (3.5, float), (7, int)]`
   - Check count: 3 != 2 → Error
   - Error: "Inconsistencies in number of arguments in function call: add"

5. **`add(5.5, 3)`**
   - Collect arguments: `[(5.5, float), (3, int)]`
   - Check count: 2 == 2 → OK
   - Check types: `float != int` → Error
   - Error: "argument 1 type mismatch in function call: add"

6. **`foo()`**
   - Lookup "foo" → Not found → Error
   - Error: "Undeclared function: foo"

### Example 4: Complex Expression

**Code**:
```c
int main() {
    int x;
    float y = 2.5;
    
    x = 5 * y;  // Warning
}
```

**Step-by-step Analysis**:

1. **Declare `int x`**
   - Insert x: `{name: "x", type: "int"}`

2. **Declare `float y = 2.5`**
   - Insert y: `{name: "y", type: "float"}`
   - `2.5` type → `float`
   - Types match → OK

3. **`x = 5 * y`**
   - Type propagation:
     - `5` → `int`
     - `y` → `float`
     - `5 * y` → `float` (int * float = float)
   - Assignment check:
     - `x` → `int`
     - `5 * y` → `float`
     - Types don't match → Warning
   - Error: "Warning: Assignment of float value into variable of integer type"

---

## <a name="implementation"></a>13. Implementation Details

### Symbol Table Lookup

#### Current Scope Lookup

```cpp
bool is_variable_declared_current_scope(string name) {
    symbol_info* temp = new symbol_info(name, "ID");
    symbol_info* found = table->lookup_current_scope(temp);
    delete temp;
    return found != NULL;
}
```

**Purpose**: Check if variable exists in current scope only (for duplicate detection).

#### Global Lookup

```cpp
symbol_info* get_variable_info(string name) {
    symbol_info* temp = new symbol_info(name, "ID");
    symbol_info* found = table->lookup(temp);  // Searches all scopes
    delete temp;
    return found;
}
```

**Purpose**: Find variable in any accessible scope (for usage checking).

### Type Propagation Implementation

Types are propagated through the expression tree:

```cpp
// Each expression node stores its type
symbol_info {
    name: "5 + 3"
    data_type: "int"  // Result type
}

// Types flow upward through the tree
term -> simple_expression -> rel_expression -> logic_expression -> expression
```

### Error Collection

Errors are collected in two files:

1. **Log file** (`*_log.txt`): All parsing information + errors
2. **Error file** (`*_error.txt`): Only errors

```cpp
// Log everything
outlog << "At line no: " << lines << " error message" << endl;

// Log only errors
errlog << "At line no: " << lines << " error message" << endl;
error_count++;
```

### Scope Management Implementation

Scopes are managed as a stack:

```cpp
// Enter scope
table->enter_scope();  // Push new scope

// Exit scope
table->print_current_scope();  // Print variables
table->exit_scope();           // Pop scope
```

### Function Parameter Tracking

Function parameters are tracked in a global vector:

```cpp
vector<pair<string, string>> current_func_params;  // (type, name) pairs

// When parsing function definition
parameter_list : type_specifier ID {
    current_func_params.push_back(($1->getname(), $2->getname()));
}

// When parsing function call
arguments : logic_expression {
    current_func_params.push_back(($1->getname(), $1->get_data_type()));
}
```

### Type Checking Flow

```
Expression Parsing
    ↓
Type Propagation (bottom-up)
    ↓
Type Checking (at assignment/operation)
    ↓
Error Reporting
```

---

## Conclusion

This semantic analyzer performs comprehensive analysis of C code by:

1. **Maintaining a symbol table** with scope management
2. **Tracking types** through all expressions
3. **Checking declarations** for duplicates and validity
4. **Verifying array usage** is correct
5. **Validating function calls** match definitions
6. **Detecting type mismatches** in assignments and operations
7. **Collecting all errors** without stopping compilation

The analyzer ensures code correctness beyond syntax, catching logical errors that would cause problems at runtime.

