module core.ast;

import syntax.token : Token;

interface Node {
    string tokenLiteral();
}

interface Statement : Node {
    void statementNode();
}

interface Expression : Node {
    void expressionNode();
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

class Identifier : Expression {
    Token token;
    string value;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
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
}

class FunctionLiteral : Expression {
    Token token;
    Identifier[] parameters;
    BlockStatement body;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class CallExpression : Expression {
    Token token;
    Expression function_;
    Expression[] arguments;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class IfExpression : Expression {
    Token token;
    Expression condition;
    BlockStatement consequence;
    BlockStatement alternative;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class ForExpression : Expression {
    Token token;
    Statement init;
    Expression condition;
    Statement update;
    BlockStatement body;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}


class IntegerLiteral : Expression {
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

class Builtin : Object {
    override string objectType() { return "BUILTIN"; }
    override string inspect() { return "builtin function"; }
    
    abstract Object call(Object[] args);
}