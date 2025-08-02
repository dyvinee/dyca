module core.object;

import std.stdio;
import std.string;
import std.array;

interface DycaObject {
    string objectType();
    string inspect();
}

class Integer : DycaObject {
    long value;
    
    this(long value) { this.value = value; }
    
    override string objectType() { return "INTEGER"; }
    override string inspect() { return value.to!string; }
}

class Boolean : DycaObject {
    bool value;
    
    this(bool value) { this.value = value; }
    
    override string objectType() { return "BOOLEAN"; }
    override string inspect() { return value ? "true" : "false"; }
}

class Null : DycaObject {
    override string objectType() { return "NULL"; }
    override string inspect() { return "null"; }
}

class ReturnValue : DycaObject {
    Object value;
    
    this(Object value) { this.value = value; }
    
    override string objectType() { return "RETURN_VALUE"; }
    override string inspect() { return value.inspect(); }
}

class DycaError : DycaObject {
    string message;
    
    this(string message) { this.message = message; }
    
    override string objectType() { return "ERROR"; }
    override string inspect() { return "Error: " ~ message; }
}

class Environment {
    DycaObject[string] store;
    Environment outer;
    
    this(Environment outer = null) {
        this.outer = outer;
    }
    
    DycaObject get(string name) {
        if (name in store) {
            return store[name];
        } else if (outer !is null) {
            return outer.get(name);
        }
        return null;
    }
    
    DycaObject set(string name, DycaObject val) {
        store[name] = val;
        return val;
    }
}