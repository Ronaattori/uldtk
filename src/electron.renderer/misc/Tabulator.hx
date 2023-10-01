package misc;

import haxe.Timer;
import data.def.TilesetDef;
import ldtk.Json.TilesetRect;
import cdb.Types.TilePos;
import cdb.Data.ColumnType;
import cdb.Data.Column;
import js.jquery.JQuery;
import haxe.Json;
import ui.modal.dialog.TextEditor;
import ui.modal.ContextMenu;
import cdb.Sheet;
import misc.JsTools;
import js.html.Element;
import haxe.extern.EitherType;
import haxe.DynamicAccess;
import tabulator.Tabulator;
import thx.csv.Csv;

class Tabulator {
	public var element:JQuery;
	public var sheet:Sheet;
	public var columns:Array<Column>;
	public var columnTypes:Map<String, ColumnType>;
	public var lines:Array<Dynamic>;
	public var tabulator:Null<tabulator.Tabulator>;

	public var sub:Null<Tabulator>;
	public var parent:EitherType<CellComponent, Dynamic>;
	
	public var castle:CastleWrapper;

	public function new(element:EitherType<String, js.html.Element>, sheet:Sheet, ?parent:EitherType<CellComponent, Dynamic>) {
		this.element = new J(element);
		this.columns = sheet.columns;
		this.columnTypes = [for (x in columns) x.name => x.type];
		this.parent = parent;
		this.sheet = sheet;
		this.castle = new CastleWrapper(sheet);
		this.lines = parent == null ? sheet.lines : getParentLines();
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
			ctx.add({
				label: new LocaleString("Add row before"),
				cb: () -> castle.addLine(row.getPosition() - 2)
			});
			ctx.add({
				label: new LocaleString("Add row after"),
				cb: () -> castle.addLine(row.getPosition() - 1)
			});
			ctx.add({
				label: new LocaleString("Delete row"),
				cb: () -> castle.deleteLine(row.getPosition() - 1)
			});
			switch column.type {
				case TTileLayer, TTilePos, TImage:
					ctx.add({
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
			castle.moveColumn(c, fromIndex, toIndex);
		});

		tabulator.on("tableBuilt",(e) -> {
			// tabulator.redraw(false);
			tabulator.validate();
		});

		return tabulator;
	}

	function getRowComponent(index:Int) {
		var row = tabulator.element.querySelectorAll(".tabulator-row")[index];
		return tabulator.getRow(row);
	}

	function getParentLines() {
		// TODO NONONONO NOT LIKE THIS
		// Please fix this this is a TEMP FIX to handle getting lines from a parent
		// Forgive me
		var lines:Array<Dynamic> = [];
		try {
			var p:CellComponent = parent;
			lines =  p.getValue();
		} catch (e) {
			var p:Dynamic = parent;
			lines = Reflect.field(p, sheet.getParent().c);
		}
		return lines;
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
				def.formatter = tilePosFormatter;
			case TBool:
				def.editor = "tickCross";
				def.formatter = "tickCross";
			case TList:
				def.formatter = listFormatter;
				def.cellClick = listClick;
			case TDynamic:
				def.formatter = dynamicFormatter;
				def.cellClick = dynamicClick;
			case TTileLayer:
				def.formatter = tileLayerFormatter;
			case TColor:
				def.formatter = colorFormatter;
			case TRef(sheetName):
				var refSheet = sheet.base.getSheet(sheetName);
				var idCol = refSheet.idCol.name;
				var nameCol = refSheet.props.displayColumn ?? idCol;
				var iconCol = refSheet.props.displayIcon;

				var values = [];
				var images = {};
				for (line in refSheet.lines) {
					var id = Reflect.field(line, idCol);
					var image = iconCol != null ? tilePosToHtmlImg(Reflect.field(line, iconCol))[0].outerHTML : null;
					Reflect.setField(images, id, image);
					values.push({
						label: Reflect.field(line, nameCol),
						value: id,
						line: line,
						image: image
					});
				}
				def.formatter = refFormatter;
				def.formatterParams = {images: images}
				def.editor = "list";
				def.editorParams = {
					values: values,
					itemFormatter: (label, value, item, element) -> {
						var content = new J("<span>");
						if (item.image != null) {
							content.append(new J(item.image));
						}
						content.append(label);
						return content[0].outerHTML;
					},
					autocomplete: true,
					listOnEmpty: true,
					allowEmpty: c.opt
				}

			case TEnum(options):
				def.editor = "list";
				def.editorParams = {
					values: [for (i => v in options) {
						label: v,
						value: i
					}],
					autocomplete: true,
					allowEmpty: c.opt,
					listOnEmpty: true
				};
				def.formatter = (c:CellComponent) -> return options[c.getValue()];

			case _:
				// TODO editors
		}
		if (!c.opt) validators.push("required");
		def.validator = validators;
		return def;
	}

	function dynamicFormatter(cell:CellComponent, formatterParams, onRendered) {
	    return sheet.base.valToString(TDynamic, cell.getValue());
	}

	function dynamicClick(e, cell:CellComponent) {
		var content = new J("<span>");
	   castle.openDynamicEditor(cell.getValue(), cell.getField(), (val) -> cell.setValue(val));
	   return content.get(0);
	}

	function colorFormatter(cell:CellComponent, formatterParams, onRendered) {
		var value = cell.getValue();
		var jColor = new J("<input type='color'/>");
		jColor.val(C.intToHex(value));
		jColor.change( ev->{
			cell.setValue(C.hexToInt(jColor.val()));
		});

		onRendered(() -> {
			misc.JsTools.parseComponents(new J(cell.getElement()));
		});
		return jColor.get(0);
	}

	function tileLayerFormatter(cell:CellComponent, formatterParams, onRendered) {
		return "#DATA";
	}

	function refFormatter(cell:CellComponent, formatterParams, onRendered) {
		var content = new J("<span>");
		var value = cell.getValue();
		var images = formatterParams.images;
		content.append(new J(Reflect.field(images, value)));
		content.append(cell.getValue() ?? "");
		return content.get(0);
	}

	function listClick(e, cell:CellComponent) {
		var cellElement = cell.getElement();
		var subSheet = sheet.base.getSheet(sheet.name + "@" + cell.getField());

		var holder = js.Browser.document.createElement("div");
		holder.classList.add("subHolder");
		var table = js.Browser.document.createElement("div");

		// Close the old subTabulator if one exists and return if we're trying to open the same one
		if (sub != null) {
			if (sub.sheet.name == subSheet.name) {
				removeSubTabulator();
				return;
			}
			removeSubTabulator();
		}

		var subTabulator = new Tabulator(table, subSheet, cell);

		holder.style.boxSizing = "border-box";
		holder.style.padding = "10px 30px 10px 10px";
		holder.style.borderTop = "1px solid #333";
		holder.style.borderBottom = "1px solid #333";

		table.style.border = "3px solid #333";
		table.style.height = "fit-content";
		table.style.width = "fit-content";

		holder.appendChild(table);
		cellElement.closest(".tabulator-row").append(holder);

		sub = subTabulator;
	}

	function listFormatter(cell:CellComponent, formatterParams, onRendered) {
		var sub = sheet.base.getSheet(sheet.name + "@" + cell.getField());
		var str = "[" + Std.string([for (x in sub.columns) x.name]) + "]";
		return str;
	}

	function removeSubTabulator() {
		sub.tabulator.destroy();
		sub.element.closest(".subHolder").remove();
		sub = null;
	}

	function tilePosFormatter(cell:CellComponent, formatterParams, onRendered) {
		var tileRectPicker = new J("<span/>");
		var tilesetSelect = new J("<span/>");
		var values:TilePos = cell.getValue();
		var select = JsTools.createTilesetSelect(Editor.ME.project, null, null, false, (uid) -> {
			var td = Editor.ME.project.defs.getTilesetDef(uid);
			var tp = createTilePos(td);
			cell.setValue(tp);
		});
		select.appendTo(tilesetSelect);
		if (values == null || (values != null && values.file == null))
			return tilesetSelect.get(0);
		var td = Editor.ME.project.defs.getTilesetDefFrom(values.file);
		if (td == null)
			return tilesetSelect.get(0);
		var jPicker = JsTools.createTilePicker(td.uid, RectOnly, td.getTileIdsFromRect(tilePosToTilesetRect(values, td)), true, (tileIds) -> {
			var tilesetRect = td.getTileRectFromTileIds(tileIds);
			cell.setValue(tilesetRectToTilePos(tilesetRect, td));
		});
		jPicker.appendTo(tileRectPicker);
		return tileRectPicker.get(0);
	}

	// LDTK uses pixels for the grid and Castle how many'th tile it is
	public static function tilePosToTilesetRect(tilePos:TilePos, td:TilesetDef):TilesetRect {
		var hei = tilePos.height != null ? tilePos.height : 1;
		var wid = tilePos.width != null ? tilePos.width : 1;
		var tilesetRect:TilesetRect = {
			tilesetUid: td.uid,
			h: hei * td.tileGridSize,
			w: wid * td.tileGridSize,
			y: tilePos.y * td.tileGridSize,
			x: tilePos.x * td.tileGridSize,
		};
		return tilesetRect;
	}

	public static function tilesetRectToTilePos(tilesetRect:TilesetRect, td:TilesetDef) {
		var tilePos:TilePos = {
			file: td.relPath,
			size: td.tileGridSize,
			height: Std.int(tilesetRect.h / td.tileGridSize),
			width: Std.int(tilesetRect.w / td.tileGridSize),
			y: Std.int(tilesetRect.y / td.tileGridSize),
			x: Std.int(tilesetRect.x / td.tileGridSize),
		}
		return tilePos;
	}

	public static function createTilePos(td:TilesetDef) {
		var tilePos:TilePos = {
			file: td.relPath,
			size: td.tileGridSize,
			height: null,
			width: null,
			y: 0,
			x: 0,
		};
		return tilePos;
	}
	function tilePosToHtmlImg(tilePos:TilePos) {
		if (tilePos.file == null)
			return null;
		var td = Editor.ME.project.defs.getTilesetDefFrom(tilePos.file);
		if (td == null)
			return null;
		var img = td.createTileHtmlImageFromRect(tilePosToTilesetRect(tilePos, td));
		return img;
	}
}
