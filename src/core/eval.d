module core.eval;

import core.ast;
import core.object;
import std.container : DList;
import std.conv : to;
import std.string : format;

class Evaluator {
    static Object eval(Node node, Environment env) {
        if (auto prog = cast(Program)node) {
            return evalProgram(prog, env);
        }
        else if (auto stmt = cast(Statement)node) {
            return evalStatement(stmt, env);
        }
        else if (auto expr = cast(Expression)node) {
            return evalExpression(expr, env);
        }
        return new Null();
    }

    static Object evalProgram(Program program, Environment env) {
        Object result;
        
        foreach (stmt; program.statements) {
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
        if (auto exprStmt = cast(ExpressionStatement)stmt) {
            return eval(exprStmt.expression, env);
        }
        else if (auto block = cast(BlockStatement)stmt) {
            return evalBlockStatement(block, env);
        }
        else if (auto ret = cast(ReturnStatement)stmt) {
            Object val = eval(ret.returnValue, env);
            if (isError(val)) return val;
            return new ReturnValue(val);
        }
        else if (auto let = cast(LetStatement)stmt) {
            Object val = eval(let.value, env);
            if (isError(val)) return val;
            env.set(let.name.value, val);
        }
        return new Null();
    }

    static Object evalExpression(Expression expr, Environment env) {
        if (auto ident = cast(Identifier)expr) {
            return evalIdentifier(ident, env);
        }
        else if (auto lit = cast(IntegerLiteral)expr) {
            return new Integer(lit.value);
        }
        else if (auto boolLit = cast(BooleanLiteral)expr) {
            return nativeBoolToBooleanObject(boolLit.value);
        }
        else if (auto prefix = cast(PrefixExpression)expr) {
            Object right = eval(prefix.right, env);
            if (isError(right)) return right;
            return evalPrefixExpression(prefix.operator, right);
        }
        else if (auto infix = cast(InfixExpression)expr) {
            Object left = eval(infix.left, env);
            if (isError(left)) return left;
            
            Object right = eval(infix.right, env);
            if (isError(right)) return right;
            
            return evalInfixExpression(infix.operator, left, right);
        }
        else if (auto ifExpr = cast(IfExpression)expr) {
            return evalIfExpression(ifExpr, env);
        }
        else if (auto call = cast(CallExpression)expr) {
            Object function = eval(call.function, env);
            if (isError(function)) return function;
            
            Object[] args = evalExpressions(call.arguments, env);
            if (args.length == 1 && isError(args[0])) {
                return args[0];
            }
            
            return applyFunction(function, args);
        }
        return new Null();
    }

    static Object evalIdentifier(Identifier node, Environment env) {
        if (auto val = env.get(node.value)) {
            return val;
        }
        
        if (auto builtin = builtins.get(node.value, null)) {
            return builtin;
        }
        
        return new Error("identifier not found: " ~ node.value);
    }

    static Object evalPrefixExpression(string op, Object right) {
        switch (op) {
            case "!":
                return evalBangOperatorExpression(right);
            case "-":
                return evalMinusPrefixOperatorExpression(right);
            default:
                return new Error("unknown operator: %s%s".format(op, right.objectType()));
        }
    }

    static Object evalInfixExpression(string op, Object left, Object right) {
        if (left.objectType() == "INTEGER" && right.objectType() == "INTEGER") {
            return evalIntegerInfixExpression(op, cast(Integer)left, cast(Integer)right);
        }
        else if (op == "==") {
            return nativeBoolToBooleanObject(left == right);
        }
        else if (op == "!=") {
            return nativeBoolToBooleanObject(left != right);
        }
        else if (left.objectType() != right.objectType()) {
            return new Error("type mismatch: %s %s %s".format(
                left.objectType(), op, right.objectType()));
        }
        else {
            return new Error("unknown operator: %s %s %s".format(
                left.objectType(), op, right.objectType()));
        }
    }

    static Object evalIntegerInfixExpression(string op, Integer left, Integer right) {
        switch (op) {
            case "+":
                return new Integer(left.value + right.value);
            case "-":
                return new Integer(left.value - right.value);
            case "*":
                return new Integer(left.value * right.value);
            case "/":
                return new Integer(left.value / right.value);
            case "<":
                return nativeBoolToBooleanObject(left.value < right.value);
            case ">":
                return nativeBoolToBooleanObject(left.value > right.value);
            case "==":
                return nativeBoolToBooleanObject(left.value == right.value);
            case "!=":
                return nativeBoolToBooleanObject(left.value != right.value);
            default:
                return new Error("unknown operator: %s %s %s".format(
                    left.objectType(), op, right.objectType()));
        }
    }

    static Boolean nativeBoolToBooleanObject(bool input) {
        return input ? new Boolean(true) : new Boolean(false);
    }

    static bool isTruthy(Object obj) {
        if (obj is null) return false;
        if (auto b = cast(Boolean)obj) return b.value;
        return true;
    }

    static bool isError(Object obj) {
        return obj !is null && obj.objectType() == "ERROR";
    }
}