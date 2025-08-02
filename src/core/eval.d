module core.eval;

import std.container : DList;
import core.ast : Node, Statement, Expression, Program, Identifier,
                  BlockStatement, FunctionLiteral, CallExpression;
import core.object : Object, Environment;

class Evaluator {
    static Object eval(Node node, Environment env) {
        if (auto prog = cast(Program)node) {
            return evalProgram(prog.statements, env);
        }
        else if (auto stmt = cast(Statement)node) {
            return evalStatement(stmt, env);
        }
        else if (auto expr = cast(Expression)node) {
            return evalExpression(expr, env);
        }
        return null;
    }

    static Object evalProgram(DList!Statement stmts, Environment env) {
        Object result;
        
        foreach (stmt; stmts) {
            result = eval(stmt, env);
            
            if (auto returnVal = cast(ReturnValue)result) {
                return returnVal.value;
            }
            else if (auto err = cast(Error)result) {
                return err;
            }
        }
        
        return result;
    }

    static Object evalStatement(Statement stmt, Environment env) {
        // Implementation would evaluate different statement types
        return null;
    }

    static Object evalExpression(Expression expr, Environment env) {
        // Implementation would evaluate different expression types
        return null;
    }
}