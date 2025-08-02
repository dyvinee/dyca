module utils.string;

import std.array;
import std.string;
import std.uni;

class StringUtils {
    static string capitalize(string s) {
        if (s.length == 0) return s;
        return s[0].toUpper().to!string ~ s[1..$].toLower();
    }

    static string reverse(string s) {
        return s.dup.reverse;
    }

    static string join(string[] parts, string delimiter) {
        return join(parts, delimiter);
    }

    static string[] split(string s, string delimiter) {
        return split(s, delimiter);
    }

    static bool contains(string s, string substr) {
        return indexOf(s, substr) != -1;
    }
}