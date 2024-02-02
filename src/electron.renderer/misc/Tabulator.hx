package misc;

import cdb.Types.TilePos;
import cdb.Data.ColumnType;
import cdb.Data.Column;
import js.jquery.JQuery;
import ui.modal.ContextMenu;
import cdb.Sheet;
import misc.JsTools;
import js.html.Element;
import haxe.extern.EitherType;
import tabulator.Tabulator;

class Tabulator {
	public var element:JQuery;
	public var sheet:Sheet;
	public var columns:Array<Column>;
	public var columnTypes:Map<String, ColumnType>;
	public var lines:Array<Dynamic>;
	public var tabulator:Null<tabulator.Tabulator>;

	public var castle:CastleWrapper;

	public function new(element:EitherType<String, js.html.Element>, sheet:Sheet, ?parentLine: Dynamic) {
		this.element = new J(element);
		this.columns = sheet.columns;
		this.columnTypes = [for (x in columns) x.name => x.type];
		this.sheet = sheet;
		this.castle = new CastleWrapper(sheet);
		
		// TList lines exist in the parent's line. We need some special treatment to get that out
		if (parentLine) {
			this.lines = Reflect.field(parentLine, sheet.getParent().c);
		} else {
			this.lines = sheet.getLines();
		}
		if (this.lines == null)
			this.lines = [];
		createTabulator();
	}

	function createTabulator() {
		var cols = [({formatter: "rownum"} : ColumnDefinition)].concat([for (c in columns) createColumnDef(c)]);
		tabulator = new tabulator.Tabulator(element.get(0), {
			data: lines,
			columns: cols,
			layout: "fitDataTable",
			movableRows: true,
			movableColumns: true,
			maxHeight: "100%",
			history: true,
			autoResize: false, // Not ideal, but fixes a TRef related crash
			columnDefaults: {
				maxWidth: 300,
			},
		});
		// Set callbacks to update Tabulator on changes
		castle.callbacks.onColumnAdd = (c) -> tabulator.addColumn(createColumnDef(c));
		castle.callbacks.onColumnDelete = (c) -> tabulator.deleteColumn(c.name);
		castle.callbacks.onColumnUpdate = (c) -> tabulator.updateColumnDefinition(c.name, createColumnDef(c));
		castle.callbacks.onLineAdd = (line, lineIndex) -> tabulator.addRow(line, lineIndex < 0, getRowComponent(Std.int(Math.max(0, lineIndex))));
		castle.callbacks.onLineDelete = (lineIndex) -> getRowComponent(lineIndex).delete();

		(js.Browser.window : Dynamic).tabulator = tabulator; // TODO remove this when debugging isnt needed
		tabulator.on("cellContext", (e, cell:CellComponent) -> {
			var ctx = new ContextMenu(e);
			var row = cell.getRow();
			var column = getColumn(cell.getColumn());
			ctx.addAction({
				label: new LocaleString("Add row before"),
				cb: () -> castle.addLine(row.getPosition() - 2)
			});
			ctx.addAction({
				label: new LocaleString("Add row after"),
				cb: () -> castle.addLine(row.getPosition() - 1)
			});
			ctx.addAction({
				label: new LocaleString("Delete row"),
				cb: () -> castle.deleteLine(row.getPosition() - 1)
			});
			switch column.type {
				case TTileLayer, TTilePos, TImage:
					ctx.addAction({
						label: new LocaleString("Change tileset"),
						cb: () -> {
							cell.setValue(null);
						}
					});
				case _:
			}
		});

		tabulator.on("headerContext", (e, columnComponent:ColumnComponent) -> {
			var column = getColumn(columnComponent);
			castle.createHeaderContextMenu(e, column);
		});
		tabulator.on("rowMoved", (row:RowComponent) -> {
			var data = row.getData();
			var fromIndex = lines.indexOf(data);
			var toIndex = row.getPosition() - 1; // getPosition index starts at 1
			castle.moveLine(data, fromIndex, toIndex);
		});
		tabulator.on("columnMoved", (column:ColumnComponent) -> {
			var c = getColumn(column);
			var fromIndex = sheet.columns.indexOf(c);
			var toIndex = tabulator.getColumns().indexOf(column) - 1; // The -1 is because of the "rownum" column
			castle.moveColumn(fromIndex, toIndex);
		});

		tabulator.on("tableBuilt",(e) -> {
			tabulator.validate();
		});

		return tabulator;
	}

	function getRowComponent(index:Int) {
		var row = tabulator.element.querySelectorAll(".tabulator-row")[index];
		return tabulator.getRow(row);
	}

	function getColumn(column:ColumnComponent) {
		for (col in sheet.columns) {
			if (column.getField() == col.name) {
				return col;
			}
		}
		return null;
	}

	public function createColumnDef(c:Column) {
		var def:ColumnDefinition = {};
		var validators:Array<EitherType<String, (CellComponent, Dynamic, Dynamic) -> Bool>> = [];
		def.title = c.name;
		def.field = c.name;
		def.hozAlign = "center";
		var t = c.type;
		function getFormatter(createEditor: (Dynamic, Column, ?Dynamic) -> JQuery) {
			return (cell:CellComponent, formatterParams, onRendered) -> {
				var column:Column = formatterParams.column;
				return createEditor(cell.getData(), column).get(0);
			}
		}
		def.formatterParams = {column: c};
		switch t {
			case TId, TString:
				def.editor = "input";
			case TInt:
				def.editor = "number";
				validators.push("integer");
			case TFloat:
				def.editor = "input";
				validators.push("float");
			case TTilePos:
				def.formatter = getFormatter(castle.createTilePosEditor);
			case TBool:
				def.formatter = getFormatter(castle.createCheckboxEditor);
			case TList:
				def.formatter = getFormatter(castle.createListEditor);
			case TDynamic:
				def.formatter = getFormatter(castle.createDynamicEditor);
			case TTileLayer:
				def.formatter = tileLayerFormatter;
			case TColor:
				def.formatter = getFormatter(castle.createColorEditor);
			case TRef(sheetName):
				var refSheet = sheet.base.getSheet(sheetName);
                var idCol = refSheet.idCol.name;
				var nameCol = refSheet.props.displayColumn ?? idCol;
				var iconCol = refSheet.props.displayIcon;

				def.editor = "list";
				var values = [];
				var icons = {};
				for (line in refSheet.getLines()) {
					var tp: Null<TilePos> = Reflect.field(line, iconCol);
					var id = Reflect.field(line, idCol);
					var obj = {
						label: Reflect.field(line, nameCol),
						value: id,
						icon: tp
					};
					values.push(obj);
					Reflect.setField(icons, id, tp);
				}
				def.editorParams = createListEditorParams(c, values);
				def.formatter = (c:CellComponent) -> {
					var id = c.getValue();
					var icon: Null<TilePos> = Reflect.field(icons, id);
					return listFormatter(id, icon);
				}

			case TEnum(options):
				def.editor = "list";
					var values = [for (i => v in options) {
						label: v,
						value: i,
						icon: null
					}];
				def.editorParams = createListEditorParams(c, values);
				def.formatter = (c:CellComponent) -> return options[c.getValue()];

			case _:
				// TODO editors
		}
		if (!c.opt) validators.push("required");
		def.validator = validators;
		return def;
	}

	// Tabulators native list formatter/editor is much faster than LDtk's advanced selects
	function listFormatter(label: String, ?icon: TilePos) {
		var content = new J("<span>");
		if (icon != null) {
			content.append(castle.tilePosToHtmlImg(icon));
		}
		content.append(label);
		return content.get(0);
	}

	function createListEditorParams(column:Column, values: Array<{label: String, value: Dynamic, icon: Null<TilePos>}>) {
		return {
			autocomplete: true,
			allowEmpty: column.opt,
			listOnEmpty: true,
			values: values,
			itemFormatter: (label, value, item, element) -> listFormatter(label, item.icon),
		};
	}

	function tileLayerFormatter(cell:CellComponent, formatterParams, onRendered) {
		return "#DATA";
	}
}
