package misc.castle;

import cdb.Data.Column;
import cdb.Data.SheetProps;
import cdb.Sheet;
import misc.castle.Line;

class SheetWrapper {
	public var lines: Array<Line> = [];
	public var columns: Array<Column>;
	public var displayColumn(get,never): String;
	var sheet: Sheet;

	public function new(sheet: Sheet) {
		this.sheet = sheet;
		this.columns = sheet.columns;

		for(line in sheet.getLines()) {
			lines.push(new Line(line, this));
		}
	}
	
	private function get_displayColumn() {
		var displayCol = sheet.props.displayColumn ?? sheet.idCol?.name;
		if (displayCol == null) displayCol = sheet.columns[0].name;
		return displayCol;
	}
	public function getColumn(name: String) {
		for (column in columns) {
			if (column.name == name) {
				return column;
			}
		}
		return null;
	}

}