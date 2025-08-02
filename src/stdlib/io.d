module stdlib.io;

import core.object : Object;
import core.ast : Builtin;
import std.stdio : write, writeln, readln;
import std.conv : to;

class PrintFunction : Builtin {
    override Object call(Object[] args) {
        if (args.length != 1) {
            return new Error("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        write(args[0].inspect());
        return new Null();
    }
}

class PrintlnFunction : Builtin {
    override Object call(Object[] args) {
        if (args.length != 1) {
            return new Error("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        writeln(args[0].inspect());
        return new Null();
    }
}

class InputFunction : Builtin {
    override Object call(Object[] args) {
        string prompt = "";
        if (args.length > 0) {
            prompt = args[0].inspect();
        }
        
        write(prompt);
        string input = readln().strip();
        return new String(input);
    }
}