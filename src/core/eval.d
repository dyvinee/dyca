module core.eval;

import std.stdio;
import std.container : DList;
import std.conv : to;
import std.format : format;
import std.string : join;
import core.ast;
import core.object;

class Evaluator {
    static Null NULL;
    static Boolean TRUE;
    static Boolean FALSE;

    static this() {
        NULL = new Null();
        TRUE = new Boolean(true);
        FALSE = new Boolean(false);
    }

    static DycaObject eval(Node node, Environment env) {
        if (auto prog = cast(Program)node) {
            return evalProgram(prog, env);
        }
        else if (auto stmt = cast(LetStatement)node) {
            DycaObject val = eval(stmt.value, env);
            if (isError(val)) return val;
            env.set(stmt.name.value, val);
            return val;
        }
        else if (auto stmt = cast(ReturnStatement)node) {
            DycaObject val = eval(stmt.returnValue, env);
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
            DycaObject[] elements = evalExpressions(expr.elements, env);
            if (elements.length == 1 && isError(elements[0])) {
                return elements[0];
            }
            return new Array(elements);
        }
        else if (auto expr = cast(Identifier)node) {
            return evalIdentifier(expr, env);
        }
        else if (auto expr = cast(PrefixExpression)node) {
            DycaObject right = eval(expr.right, env);
            if (isError(right)) return right;
            return evalPrefixExpression(expr.operator, right);
        }
        else if (auto expr = cast(InfixExpression)node) {
            DycaObject left = eval(expr.left, env);
            if (isError(left)) return left;
            
            DycaObject right = eval(expr.right, env);
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
            DycaObject func = eval(expr.function_, env);
            if (isError(func)) return func;
            
            DycaObject[] args = evalExpressions(expr.arguments, env);
            if (args.length == 1 && isError(args[0])) {
                return args[0];
            }
            
            return applyFunction(func, args);
        }
        else if (auto expr = cast(IndexExpression)node) {
            DycaObject left = eval(expr.left, env);
            if (isError(left)) return left;
            
            DycaObject index = eval(expr.index, env);
            if (isError(index)) return index;
            
            return evalIndexExpression(left, index);
        }
        
        return NULL;
    }

    static DycaObject evalProgram(Program program, Environment env) {
        DycaObject result;
        
        foreach (stmt; program.statements) {
            result = eval(stmt, env);
            
            if (auto returnVal = cast(ReturnValue)result) {
                return returnVal.value;
            }
            else if (auto err = cast(DycaError)result) {
                return err;
            }
        }
        
        return result;
    }

    static DycaObject evalBlockStatement(BlockStatement block, Environment env) {
        DycaObject result;
        
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

    static DycaObject evalPrefixExpression(string op, DycaObject right) {
        switch (op) {
            case "!":
                return evalBangOperatorExpression(right);
            case "-":
                return evalMinusPrefixOperatorExpression(right);
            default:
                return new DycaError("unknown operator: %s%s".format(op, right.objectType()));
        }
    }

    static DycaObject evalBangOperatorExpression(DycaObject right) {
        if (right is NULL) return TRUE;
        if (right is FALSE) return TRUE;
        return FALSE;
    }

    static DycaObject evalMinusPrefixOperatorExpression(DycaObject right) {
        if (right.objectType() != "INTEGER") {
            return new DycaError("unknown operator: -%s".format(right.objectType()));
        }
        
        long value = (cast(Integer)right).value;
        return new Integer(-value);
    }

    static DycaObject evalInfixExpression(string op, DycaObject left, DycaObject right) {
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
            return new DycaError("type mismatch: %s %s %s".format(
                left.objectType(), op, right.objectType()));
        }
        else {
            return new DycaError("unknown operator: %s %s %s".format(
                left.objectType(), op, right.objectType()));
        }
    }

    static DycaObject evalIntegerInfixExpression(string op, DycaObject left, DycaObject right) {
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
                return new DycaError("unknown operator: %s %s %s".format(
                    left.objectType(), op, right.objectType()));
        }
    }

    static DycaObject evalStringInfixExpression(string op, DycaObject left, DycaObject right) {
        if (op != "+") {
            return new DycaError("unknown operator: %s %s %s".format(
                left.objectType(), op, right.objectType()));
        }
        
        string leftVal = (cast(String)left).value;
        string rightVal = (cast(String)right).value;
        return new String(leftVal ~ rightVal);
    }

    static DycaObject evalIfExpression(IfExpression expr, Environment env) {
        DycaObject condition = eval(expr.condition, env);
        if (isError(condition)) return condition;
        
        if (isTruthy(condition)) {
            return eval(expr.consequence, env);
        } else if (expr.alternative !is null) {
            return eval(expr.alternative, env);
        } else {
            return NULL;
        }
    }

    static DycaObject evalIdentifier(Identifier node, Environment env) {
        if (auto val = env.get(node.value)) {
            return val;
        }
        
        if (auto builtin = builtins.get(node.value, null)) {
            return builtin;
        }
        
        return new DycaError("identifier not found: " ~ node.value);
    }

    static DycaObject[] evalExpressions(Expression[] exprs, Environment env) {
        DycaObject[] result;
        
        foreach (expr; exprs) {
            DycaObject evaluated = eval(expr, env);
            if (isError(evaluated)) {
                return [evaluated];
            }
            result ~= evaluated;
        }
        
        return result;
    }

    static DycaObject applyFunction(DycaObject fn, DycaObject[] args) {
        if (auto func = cast(Function)fn) {
            Environment extendedEnv = extendFunctionEnv(func, args);
            DycaObject evaluated = eval(func.body, extendedEnv);
            return unwrapReturnValue(evaluated);
        }
        else if (auto builtin = cast(Builtin)fn) {
            return builtin.call(args);
        }
        else {
            return new DycaError("not a function: %s".format(fn.objectType()));
        }
    }

    static Environment extendFunctionEnv(Function func, DycaObject[] args) {
        Environment env = new Environment(func.env);
        
        for (size_t i = 0; i < func.parameters.length; i++) {
            env.set(func.parameters[i].value, args[i]);
        }
        
        return env;
    }

    static DycaObject evalIndexExpression(DycaObject left, DycaObject index) {
        if (left.objectType() == "ARRAY" && index.objectType() == "INTEGER") {
            return evalArrayIndexExpression(left, index);
        }
        return new DycaError("index operator not supported: %s".format(left.objectType()));
    }

    static DycaObject evalArrayIndexExpression(DycaObject array, DycaObject index) {
        DycaObject[] elements = (cast(Array)array).elements;
        long idx = (cast(Integer)index).value;
        
        if (idx < 0 || idx >= elements.length) {
            return NULL;
        }
        
        return elements[idx];
    }

    static DycaObject unwrapReturnValue(DycaObject obj) {
        if (auto returnVal = cast(ReturnValue)obj) {
            return returnVal.value;
        }
        return obj;
    }

    static Boolean nativeBoolToBooleanObject(bool input) {
        return input ? TRUE : FALSE;
    }

    static bool isTruthy(DycaObject obj) {
        if (obj is NULL) return false;
        if (obj is FALSE) return false;
        if (obj is TRUE) return true;
        return true;
    }

    static bool isError(DycaObject obj) {
        return obj !is null && obj.objectType() == "ERROR";
    }

    static Builtin[string] builtins = [
        "len": new LenFunction(),
        "first": new FirstFunction(),
        "last": new LastFunction(),
        "rest": new RestFunction(),
        "push": new PushFunction(),
        "puts": new PutsFunction()
    ];
}

class LenFunction : Builtin {
    override DycaObject call(DycaObject[] args) {
        if (args.length != 1) {
            return new DycaError("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        if (auto str = cast(String)args[0]) {
            return new Integer(str.value.length);
        }
        else if (auto arr = cast(Array)args[0]) {
            return new Integer(arr.elements.length);
        }
        
        return new DycaError("argument to `len` not supported, got %s".format(args[0].objectType()));
    }
}

class FirstFunction : Builtin {
    override DycaObject call(DycaObject[] args) {
        if (args.length != 1) {
            return new DycaError("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        if (args[0].objectType() != "ARRAY") {
            return new DycaError("argument to `first` must be ARRAY, got %s".format(args[0].objectType()));
        }
        
        DycaObject[] arr = (cast(Array)args[0]).elements;
        if (arr.length > 0) {
            return arr[0];
        }
        
        return Evaluator.NULL;
    }
}

class LastFunction : Builtin {
    override DycaObject call(DycaObject[] args) {
        if (args.length != 1) {
            return new DycaError("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        if (args[0].objectType() != "ARRAY") {
            return new DycaError("argument to `last` must be ARRAY, got %s".format(args[0].objectType()));
        }
        
        DycaObject[] arr = (cast(Array)args[0]).elements;
        if (arr.length > 0) {
            return arr[$-1];
        }
        
        return Evaluator.NULL;
    }
}

class RestFunction : Builtin {
    override DycaObject call(DycaObject[] args) {
        if (args.length != 1) {
            return new DycaError("wrong number of arguments. got=%d, want=1".format(args.length));
        }
        
        if (args[0].objectType() != "ARRAY") {
            return new DycaError("argument to `rest` must be ARRAY, got %s".format(args[0].objectType()));
        }
        
        DycaObject[] arr = (cast(Array)args[0]).elements;
        if (arr.length == 0) {
            return Evaluator.NULL;
        }
        
        return new Array(arr[1..$]);
    }
}

class PushFunction : Builtin {
    override DycaObject call(DycaObject[] args) {
        if (args.length != 2) {
            return new DycaError("wrong number of arguments. got=%d, want=2".format(args.length));
        }
        
        if (args[0].objectType() != "ARRAY") {
            return new DycaError("first argument to `push` must be ARRAY, got %s".format(args[0].objectType()));
        }
        
        DycaObject[] arr = (cast(Array)args[0]).elements.dup;
        arr ~= args[1];
        return new Array(arr);
    }
}

class PutsFunction : Builtin {
    override DycaObject call(DycaObject[] args) {
        foreach (arg; args) {
            writeln(arg.inspect());
        }
        return Evaluator.NULL;
    }
}