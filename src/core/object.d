module core.object;

import std.stdio;
import std.string;
import std.array;

interface Object {
    string objectType();
    string inspect();
}

class Integer : Object {
    long value;
    
    this(long value) { this.value = value; }
    
    override string objectType() { return "INTEGER"; }
    override string inspect() { return value.to!string; }
}

class Boolean : Object {
    bool value;
    
    this(bool value) { this.value = value; }
    
    override string objectType() { return "BOOLEAN"; }
    override string inspect() { return value ? "true" : "false"; }
}

class Null : Object {
    override string objectType() { return "NULL"; }
    override string inspect() { return "null"; }
}

class ReturnValue : Object {
    Object value;
    
    this(Object value) { this.value = value; }
    
    override string objectType() { return "RETURN_VALUE"; }
    override string inspect() { return value.inspect(); }
}

class Error : Object {
    string message;
    
    this(string message) { this.message = message; }
    
    override string objectType() { return "ERROR"; }
    override string inspect() { return "Error: " ~ message; }
}

class Environment {
    Object[string] store;
    Environment outer;
    
    this(Environment outer = null) {
        this.outer = outer;
    }
    
    Object get(string name) {
        if (name in store) {
            return store[name];
        } else if (outer !is null) {
            return outer.get(name);
        }
        return null;
    }
    
    Object set(string name, Object val) {
        store[name] = val;
        return val;
    }
}