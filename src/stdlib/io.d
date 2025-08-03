module stdlib.io;

import core.object : DycaObject, DycaError, Null;
import core.ast : Builtin;
import std.stdio : write, writeln, readln;
import std.conv : to;


class String : DycaObject {
    string value;
    
    this(string value) { this.value = value; }
    
    override string objectType() { return "STRING"; }
    override string inspect() { return value; }
}


class PrintFunction : Builtin {
    override DycaObject call(DycaObject[] args) { 
        if (args.length != 1) {
            return new DycaError("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        write(args[0].inspect());
        return new Null();
    }
}

class PrintlnFunction : Builtin {
    override DycaObject call(DycaObject[] args) { 
        if (args.length != 1) {
            return new DycaError("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        writeln(args[0].inspect());
        return new Null();
    }
}

class InputFunction : Builtin {
    override DycaObject call(DycaObject[] args) { 
        string prompt = "";
        if (args.length > 0) {
            prompt = args[0].inspect();
        }
        
        write(prompt);
        string input = readln().strip();
        return new String(input);
    }
}