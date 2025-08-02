module main;

import std.stdio : writeln, stderr;
import std.file : readText;
import std.path : buildPath;
import core.lexer : Lexer;
import core.parser : Parser;
import core.eval : Evaluator;
import core.object : newEnvironment;

void main(string[] args) {
    if (args.length < 2) {
        stderr.writeln("Usage: dyca <file.dyca>");
        return;
    }

    string filePath = args[1];
    string input = readText(filePath);

    Lexer lexer = new Lexer(input);
    Parser parser = new Parser(lexer);
    Program program = parser.parseProgram();

    if (parser.errors.length > 0) {
        stderr.writeln("Parser errors:");
        foreach (error; parser.errors) {
            stderr.writeln("\t", error);
        }
        return;
    }

    auto env = newEnvironment();
    auto evaluated = Evaluator.eval(program, env);

    if (evaluated !is null) {
        writeln(evaluated.inspect());
    }
}