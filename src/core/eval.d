module core.eval;

import core.ast;
import core.object;
import std.container : DList;
import std.conv : to;
import std.format : format;
import std.string : join;

class Evaluator {
    static Object eval(Node node, Environment env) {
        if (auto prog = cast(Program)node) {
            return evalProgram(prog, env);
        }
        else if (auto stmt = cast(LetStatement)node) {
            Object val = eval(stmt.value, env);
            if (isError(val)) return val;
            env.set(stmt.name.value, val);
        }
        else if (auto stmt = cast(ReturnStatement)node) {
            Object val = eval(stmt.returnValue, env);
            if (isError(val)) return val;
            return new ReturnValue(val);
        }
        else if (auto stmt = cast(ExpressionStatement)node) {
            return eval(stmt.expression, env);
        }
        else if (auto stmt = cast(BlockStatement)node) {
            return evalBlockStatement(stmt, env);
        }
        else if (auto expr = cast(IntegerLiteral)node) {
            return new Integer(expr.value);
        }
        else if (auto expr = cast(BooleanLiteral)node) {
            return nativeBoolToBooleanObject(expr.value);
        }
        else if (auto expr = cast(StringLiteral)node) {
            return new String(expr.value);
        }
        else if (auto expr = cast(ArrayLiteral)node) {
            Object[] elements = evalExpressions(expr.elements, env);
            if (elements.length == 1 && isError(elements[0])) {
                return elements[0];
            }
            return new Array(elements);
        }
        else if (auto expr = cast(Identifier)node) {
            return evalIdentifier(expr, env);
        }
        else if (auto expr = cast(PrefixExpression)node) {
            Object right = eval(expr.right, env);
            if (isError(right)) return right;
            return evalPrefixExpression(expr.operator, right);
        }
        else if (auto expr = cast(InfixExpression)node) {
            Object left = eval(expr.left, env);
            if (isError(left)) return left;
            
            Object right = eval(expr.right, env);
            if (isError(right)) return right;
            
            return evalInfixExpression(expr.operator, left, right);
        }
        else if (auto expr = cast(IfExpression)node) {
            return evalIfExpression(expr, env);
        }
        else if (auto expr = cast(FunctionLiteral)node) {
            return new Function(expr.parameters, expr.body, env);
        }
        else if (auto expr = cast(CallExpression)node) {
            Object func = eval(expr.function_, env);
            if (isError(func)) return func;
            
            Object[] args = evalExpressions(expr.arguments, env);
            if (args.length == 1 && isError(args[0])) {
                return args[0];
            }
            
            return applyFunction(func, args);
        }
        else if (auto expr = cast(IndexExpression)node) {
            Object left = eval(expr.left, env);
            if (isError(left)) return left;
            
            Object index = eval(expr.index, env);
            if (isError(index)) return index;
            
            return evalIndexExpression(left, index);
        }
        
        return null;
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

    static Object evalBlockStatement(BlockStatement block, Environment env) {
        Object result;
        
        foreach (stmt; block.statements) {
            result = eval(stmt, env);
            
            if (result !is null && 
                (result.objectType() == "RETURN_VALUE" || 
                 result.objectType() == "ERROR")) {
                return result;
            }
        }
        
        return result;
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

    static Object evalBangOperatorExpression(Object right) {
        if (right is NULL) return new Boolean(true);
        if (right is FALSE) return new Boolean(true);
        return new Boolean(false);
    }

    static Object evalMinusPrefixOperatorExpression(Object right) {
        if (right.objectType() != "INTEGER") {
            return new Error("unknown operator: -%s".format(right.objectType()));
        }
        
        long value = (cast(Integer)right).value;
        return new Integer(-value);
    }

    static Object evalInfixExpression(string op, Object left, Object right) {
        if (left.objectType() == "INTEGER" && right.objectType() == "INTEGER") {
            return evalIntegerInfixExpression(op, left, right);
        }
        else if (left.objectType() == "STRING" && right.objectType() == "STRING") {
            return evalStringInfixExpression(op, left, right);
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

    static Object evalIntegerInfixExpression(string op, Object left, Object right) {
        long leftVal = (cast(Integer)left).value;
        long rightVal = (cast(Integer)right).value;
        
        switch (op) {
            case "+":
                return new Integer(leftVal + rightVal);
            case "-":
                return new Integer(leftVal - rightVal);
            case "*":
                return new Integer(leftVal * rightVal);
            case "/":
                return new Integer(leftVal / rightVal);
            case "<":
                return nativeBoolToBooleanObject(leftVal < rightVal);
            case ">":
                return nativeBoolToBooleanObject(leftVal > rightVal);
            case "==":
                return nativeBoolToBooleanObject(leftVal == rightVal);
            case "!=":
                return nativeBoolToBooleanObject(leftVal != rightVal);
            default:
                return new Error("unknown operator: %s %s %s".format(
                    left.objectType(), op, right.objectType()));
        }
    }

    static Object evalStringInfixExpression(string op, Object left, Object right) {
        if (op != "+") {
            return new Error("unknown operator: %s %s %s".format(
                left.objectType(), op, right.objectType()));
        }
        
        string leftVal = (cast(String)left).value;
        string rightVal = (cast(String)right).value;
        return new String(leftVal ~ rightVal);
    }

    static Object evalIfExpression(IfExpression expr, Environment env) {
        Object condition = eval(expr.condition, env);
        if (isError(condition)) return condition;
        
        if (isTruthy(condition)) {
            return eval(expr.consequence, env);
        } else if (expr.alternative !is null) {
            return eval(expr.alternative, env);
        } else {
            return NULL;
        }
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

    static Object[] evalExpressions(Expression[] exprs, Environment env) {
        Object[] result;
        
        foreach (expr; exprs) {
            Object evaluated = eval(expr, env);
            if (isError(evaluated)) {
                return [evaluated];
            }
            result ~= evaluated;
        }
        
        return result;
    }

    static Object applyFunction(Object fn, Object[] args) {
        if (auto func = cast(Function)fn) {
            Environment extendedEnv = extendFunctionEnv(function, args);
            Object evaluated = eval(function.body, extendedEnv);
            return unwrapReturnValue(evaluated);
        }
        else if (auto builtin = cast(Builtin)fn) {
            return builtin.call(args);
        }
        else {
            return new Error("not a function: %s".format(fn.objectType()));
        }
    }

    static Environment extendFunctionEnv(Function func, Object[] args) {
        Environment env = new Environment(func.env);
        
        for (size_t i = 0; i < func.parameters.length; i++) {
            env.set(func.parameters[i].value, args[i]);
        }
        
        return env;
    }

    static Object evalIndexExpression(Object left, Object index) {
        if (left.objectType() == "ARRAY" && index.objectType() == "INTEGER") {
            return evalArrayIndexExpression(left, index);
        }
        return new Error("index operator not supported: %s".format(left.objectType()));
    }

    static Object evalArrayIndexExpression(Object array, Object index) {
        Object[] elements = (cast(Array)array).elements;
        long idx = (cast(Integer)index).value;
        
        if (idx < 0 || idx >= elements.length) {
            return NULL;
        }
        
        return elements[idx];
    }

    static Object unwrapReturnValue(Object obj) {
        if (auto returnVal = cast(ReturnValue)obj) {
            return returnVal.value;
        }
        return obj;
    }

    static Boolean nativeBoolToBooleanObject(bool input) {
        return input ? TRUE : FALSE;
    }

    static bool isTruthy(Object obj) {
        if (obj is NULL) return false;
        if (obj is FALSE) return false;
        if (obj is TRUE) return true;
        return true;
    }

    static bool isError(Object obj) {
        return obj !is null && obj.objectType() == "ERROR";
    }

    // Built-in constants
    static Null NULL = new Null();
    static Boolean TRUE = new Boolean(true);
    static Boolean FALSE = new Boolean(false);

    // Built-in functions
    static Builtin[string] builtins = [
        "len": new LenFunction(),
        "first": new FirstFunction(),
        "last": new LastFunction(),
        "rest": new RestFunction(),
        "push": new PushFunction(),
        "puts": new PutsFunction()
    ];
}

// Built-in function implementations
class LenFunction : Builtin {
    override Object call(Object[] args) {
        if (args.length != 1) {
            return new Error("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        if (auto str = cast(String)args[0]) {
            return new Integer(str.value.length);
        }
        else if (auto arr = cast(Array)args[0]) {
            return new Integer(arr.elements.length);
        }
        
        return new Error("argument to `len` not supported, got %s".format(args[0].objectType()));
    }
}

class FirstFunction : Builtin {
    override Object call(Object[] args) {
        if (args.length != 1) {
            return new Error("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        if (args[0].objectType() != "ARRAY") {
            return new Error("argument to `first` must be ARRAY, got %s".format(args[0].objectType()));
        }
        
        Object[] arr = (cast(Array)args[0]).elements;
        if (arr.length > 0) {
            return arr[0];
        }
        
        return Evaluator.NULL;
    }
}

class PutsFunction : Builtin {
    override Object call(Object[] args) {
        foreach (arg; args) {
            writeln(arg.inspect());
        }
        return Evaluator.NULL;
    }
}