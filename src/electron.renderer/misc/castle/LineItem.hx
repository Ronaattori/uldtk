package misc.castle;

import cdb.Data.Column;
import haxe.extern.EitherType;
import haxe.DynamicAccess;

class LineItem {
    public var column: Column;
    public var value: Dynamic;
    public var sheet: SheetWrapper;

    public function new(column: EitherType<Column, String>, value: Dynamic, sheet: SheetWrapper) {
        this.value = value;
        this.sheet = sheet;

        if (column is String) {
            this.column = sheet.getColumn(column);
        } else {
            this.column = column;
        }
    }
    
}