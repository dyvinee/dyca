module stdlib.io;

import core.object : DycaObject, DycaError, Null, String;
import core.ast : Builtin;
import std.stdio : write, writeln, readln;
import std.conv : to;

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
            if (auto str = cast(String)args[0]) {
                prompt = str.value;
            } else {
                return new DycaError("input prompt must be a string, got %s".format(args[0].objectType()));
            }
        }
        
        write(prompt);
        string input = readln().strip();
        return new String(input);
    }
}