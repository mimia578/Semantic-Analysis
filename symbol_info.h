#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    string symbol_type = "NAN"; // variable, array, or function
    string data_type; // int, float, void
    string return_type;
    vector<pair<string, string>> parameters; // (type, name) pairs
    int array_size;

public:

    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->array_size = 0;
    }

    string get_name()
    {
        return name;
    }
    
    // Add alias for compatibility
    string getname()
    {
        return name;
    }

    string get_type()
    {
        return type;
    }

    string get_symbol_type()
    {
        return symbol_type;
    }

    string get_data_type()
    {
        return data_type;
    }

    string get_return_type()
    {
        return return_type;
    }

    int get_array_size()
    {
        return array_size;
    }

    vector<pair<string, string>> get_parameters()
    {
        return parameters;
    }

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }

    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }

    void set_return_type(string return_type)
    {
        this->return_type = return_type;
    }

    void set_array_size(int size)
    {
        this->array_size = size;
    }

    void add_parameter(string type, string name)
    {
        parameters.push_back(make_pair(type, name));
    }
};

#endif