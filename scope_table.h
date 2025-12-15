#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;
 
    int hash_function(string name)
    {
        unsigned long hash = 5381;
        for (char c : name) {
            hash = ((hash << 5) + hash) + c;
        }
        return hash % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();
};

scope_table::scope_table()
{
    this->bucket_count = 10;
    this->unique_id = 1;
    this->parent_scope = NULL;
    table.resize(bucket_count);
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    table.resize(bucket_count);
}

scope_table *scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info *scope_table::lookup_in_scope(symbol_info* symbol)
{
    int bucket_index = hash_function(symbol->get_name());
    
    for (auto it = table[bucket_index].begin(); it != table[bucket_index].end(); it++)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            return *it;
        }
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    if (lookup_in_scope(symbol) != NULL)
    {
        return false;
    }
    
    int bucket_index = hash_function(symbol->get_name());
    table[bucket_index].push_back(symbol);
    return true;
}

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    int bucket_index = hash_function(symbol->get_name());
    
    for (auto it = table[bucket_index].begin(); it != table[bucket_index].end(); it++)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            table[bucket_index].erase(it);
            return true;
        }
    }
    return false;
}

void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # " << unique_id << endl;
    
    for (int i = 0; i < bucket_count; i++)
    {
        if (!table[i].empty())
        {
            outlog << i << " --> " << endl;
            
            for (auto it = table[i].begin(); it != table[i].end(); it++)
            {
                outlog << "< " << (*it)->get_name() << " : " << (*it)->get_type() << " >" << endl;
                
                if ((*it)->get_symbol_type() == "function")
                {
                    outlog << "Function Definition" << endl;
                    outlog << "Return Type: " << (*it)->get_return_type() << endl;
                    
                    vector<pair<string, string>> params = (*it)->get_parameters();
                    outlog << "Number of Parameters: " << params.size() << endl;
                    outlog << "Parameter Details: ";
                    
                    for (int j = 0; j < params.size(); j++)
                    {
                        outlog << params[j].first;
                        if (!params[j].second.empty())
                            outlog << " " << params[j].second;
                        if (j < params.size() - 1)
                            outlog << ", ";
                    }
                    outlog << endl;
                }
                else if ((*it)->get_symbol_type() == "array")
                {
                    outlog << "Array" << endl;
                    outlog << "Type: " << (*it)->get_data_type() << endl;
                    outlog << "Size: " << (*it)->get_array_size() << endl;
                }
                else if ((*it)->get_symbol_type() == "variable")
                {
                    outlog << "Variable" << endl;
                    outlog << "Type: " << (*it)->get_data_type() << endl;
                }
                outlog << endl;
            }
        }
    }
    outlog << endl;
}

scope_table::~scope_table()
{
    for (int i = 0; i < bucket_count; i++)
    {
        for (auto it = table[i].begin(); it != table[i].end(); it++)
        {
            delete *it;
        }
        table[i].clear();
    }
}