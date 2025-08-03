module core.ast;

import std.array;
import std.conv;
import std.stdio;
import std.string;
import core.object;
import syntax.token : Token;

interface Node {
    string tokenLiteral();
}

interface Statement : Node {
    void statementNode();
    string toString();
}

interface Expression : Node {
    void expressionNode();
    string toString();
}

class Program {
    Statement[] statements;
    
    string tokenLiteral() {
        if (statements.length > 0) {
            return statements[0].tokenLiteral();
        }
        return "";
    }
}

class Function : DycaObject {
    Identifier[] parameters;
    BlockStatement body;
    Environment env;
    
    this(Identifier[] parameters, BlockStatement body, Environment env) {
        this.parameters = parameters;
        this.body = body;
        this.env = env;
    }
    
    override string objectType() { return "FUNCTION"; }
    override string inspect() {
        string[] params;
        foreach (p; parameters) {
            params ~= p.toString();
        }
        return "function(" ~ join(params, ", ") ~ ") {\n" ~ body.toString() ~ "\n}";
    }
}

class Identifier : Expression {
    Token token;
    string value;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() { return value; }
}

class ImportStatement : Statement {
    Token token;
    string[] path;
    string alias_;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class ExportStatement : Statement {
    Token token;
    string[] path;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class BlockStatement : Statement {
    Token token;
    Statement[] statements;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        string[] stmts;
        foreach (s; statements) {
            stmts ~= s.toString();
        }
        return "{\n" ~ join(stmts, "\n") ~ "\n}";
    }
}

class FunctionLiteral : Expression {
    Token token;
    Identifier[] parameters;
    BlockStatement body;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        string[] params;
        foreach (p; parameters) {
            params ~= p.toString();
        }
        return tokenLiteral() ~ "(" ~ join(params, ", ") ~ ") " ~ body.toString();
    }
}

class CallExpression : Expression {
    Token token;
    Expression function_;
    Expression[] arguments;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        string[] args;
        foreach (arg; arguments) {
            args ~= arg.toString();
        }
        return function_.toString() ~ "(" ~ join(args, ", ") ~ ")";
    }
}

class IfExpression : Expression {
    Token token;
    Expression condition;
    BlockStatement consequence;
    BlockStatement alternative;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        string s = "if" ~ condition.toString() ~ " " ~ consequence.toString();
        if (alternative !is null) {
            s ~= " else " ~ alternative.toString();
        }
        return s;
    }
}

class ForExpression : Expression {
    Token token;
    Statement init;
    Expression condition;
    Statement update;
    BlockStatement body;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        return "for(" ~ init.toString() ~ "; " ~ condition.toString() ~ "; " ~ 
               update.toString() ~ ") " ~ body.toString();
    }
}

class IntegerLiteral : Expression {
    Token token;
    long value;
    
    this(Token token, long value) {
        this.token = token;
        this.value = value;
    }
    
    override void expressionNode() {}
    override string tokenLiteral() { return token.literal; }
    override string toString() { return value.to!string; }
}

class BooleanLiteral : Expression {
    Token token;
    bool value;
    
    this(Token token, bool value) {
        this.token = token;
        this.value = value;
    }
    
    override void expressionNode() {}
    override string tokenLiteral() { return token.literal; }
    override string toString() { return value ? "true" : "false"; }
}

class PrefixExpression : Expression {
    Token token;
    string op;
    Expression right;
    
    this(Token token, string op, Expression right) {
        this.token = token;
        this.op = op;
        this.right = right;
    }
    
    override void expressionNode() {}
    override string tokenLiteral() { return token.literal; }
    override string toString() {
        return "(" ~ op ~ right.toString() ~ ")";
    }
}

class InfixExpression : Expression {
    Token token;
    Expression left;
    string op;
    Expression right;
    
    this(Token token, Expression left, string op, Expression right) {
        this.token = token;
        this.left = left;
        this.op = op;
        this.right = right;
    }
    
    override void expressionNode() {}
    override string tokenLiteral() { return token.literal; }
    override string toString() {
        return "(" ~ left.toString() ~ " " ~ op ~ " " ~ right.toString() ~ ")";
    }
}

class LetStatement : Statement {
    Token token;
    Identifier name;
    Expression value;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class ReturnStatement : Statement {
    Token token;
    Expression returnValue;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class ExpressionStatement : Statement {
    Token token;
    Expression expression;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class StringLiteral : Expression {
    Token token;
    string value;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() { return value; }
}

class ArrayLiteral : Expression {
    Token token;
    Expression[] elements;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        string[] elems;
        foreach (e; elements) {
            elems ~= e.toString();
        }
        return "[" ~ join(elems, ", ") ~ "]";
    }
}

class IndexExpression : Expression {
    Token token;
    Expression left;
    Expression index;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
    override string toString() {
        return "(" ~ left.toString() ~ "[" ~ index.toString() ~ "])";
    }
}

class Builtin : DycaObject {
    override string objectType() { return "BUILTIN"; }
    override string inspect() { return "builtin function"; }
    
    abstract DycaObject call(DycaObject[] args);
}