package ui;

import sortablejs.Sortable.SortableDragEvent;
import js.jquery.JQuery;
import cdb.Data.ColumnType;
import haxe.Json;
import ui.modal.dialog.TextEditor;
import cdb.Data.Column;

class SheetDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.rowList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");
	var sheet : cdb.Sheet;
	var curLine : Null<Dynamic>;
	var singleLine : Bool;
	public var castle:CastleWrapper;


	public function new(sheet:cdb.Sheet, ?singleLine: Dynamic) {
		this.sheet = sheet;
		this.curLine = singleLine == null ? sheet.lines[0] : singleLine;
		this.castle = new CastleWrapper(sheet);
		this.singleLine = singleLine != null;

		jWrapper = new J('<div class="sheetDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("sheetDefsForm"));
		jWrapper.width("750px");

		// Only show the editors in single line mode
		if (singleLine) {
			jList.remove();
			jWrapper.find(".buttons").remove();
		}
		
		jWrapper.find(".createRow").click(e -> {
			var l = sheet.newLine();
			selectLine(l);
		});
		jWrapper.find(".createColumn").click(e -> {
			// sheet.addColumn()
			new ui.modal.dialog.CastleColumn(sheet, (c) -> {
				updateForm();
			});
		});
		castle.callbacks.onColumnDelete = (c: Column) -> new J('#${getEditorId(c)}').closest(".line").remove();

		updateList();
		updateForm();
	}
	public function selectLine(line) {
		curLine = line;
		updateList();
		updateForm();
	}
	function getEditorId(column: Column) {
		return 'editor_${column.name}';
	}

	public function refreshLine(column: Column) {
		var editorId = getEditorId(column);
		var oldEditor = new J('#$editorId');
		if (oldEditor.length > 0) {
			var newEditor = getEditor(column, curLine);
			newEditor.attr("id",editorId);
			newEditor.addClass("editor");
			oldEditor.replaceWith(newEditor);
		}
	}

	public function updateList(){
		if (singleLine) {
			return;
		}

		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul class="niceList compact"/>');
		jSubList.appendTo(jLi);

		for(line in sheet.lines) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+Reflect.field(line, castle.getDisplayColumn())+'</span>');

			if( line==curLine )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectLine(line);
			});
			ui.modal.ContextMenu.attachTo(jLi, [
				{
					label: L._Delete(),
					cb: () -> {},
				},
			]);
		}

		// Make list sortable
		JsTools.makeSortable(jSubList, function(ev: SortableDragEvent) {
			castle.moveLine(ev.oldIndex, ev.newIndex);
		});
	}
		
	public function updateForm(){
		if( curLine==null ) {
			jForm.hide();
			return;
		}
		jForm.show();
		jForm.empty();
		for (column in sheet.columns) {
			var name = column.name;
			var editorId = getEditorId(column);
			var jLine = new J("<div class='line'>");
			var jLabel = new J('<label for=$editorId><button class="gray">$name</button></label>');
			var jInfo = new J('<div class="info">${getInfo(column.type)}</div>)');

			// Add the info into the line
			jInfo.appendTo(jLabel);
			jLabel.appendTo(jLine);
			jLabel.addClass("sortHandle");

			// Get and add the editor into the line
			var editor = getEditor(column, curLine);
			editor.attr("id", editorId);
			editor.addClass("editor");
			editor.appendTo(jLine);
			
			jLabel.on("contextmenu", (e:js.jquery.Event) -> {
				castle.createHeaderContextMenu(e, column);
			});

			jForm.append(jLine);
		}
		JsTools.makeSortable(jForm, function(ev:sortablejs.Sortable.SortableDragEvent) {
			castle.moveColumn(ev.oldIndex, ev.newIndex);
		});

		JsTools.parseComponents(jForm);
	}

	function getEditor(column:Column, line:Dynamic) {
		switch (column.type) {
			case TString, TId:
				return castle.createInputEditor(line, column);
			case TTilePos:
				var editor = castle.createTilePosEditor(line, column, (_) -> refreshLine(column));
				editor.css("flex", "unset");
				return editor;
			case TDynamic:
				return castle.createDynamicEditor(line, column);
			case TEnum(_), TRef(_):
				return castle.createSelectEditor(line, column);
			case TList:
				var jContainer = new J("<div>");
				var subSheet = sheet.getSub(column);
				var tabualtor = new misc.Tabulator(jContainer.get(0), subSheet, line);
				return jContainer;
			case TBool:
				return castle.createCheckboxEditor(line, column);
			case TColor:
				return castle.createColorEditor(line, column);
			case _:
				var todo = new J("<span>");
				todo[0].innerHTML = "TODO";
				return todo;
		}
	}
	function getInfo(type:ColumnType) {
		return switch (type) {
			case TId:
				"This is an unique identifier for the current row. It allows referencing this row from other sheets or columns. Unique identifiers must be valid code identifiers [A-Za-z_][A-Za-z0_9_]*";
			case TString:
				"Any text can be input into this column. CastleDB currently does not allow multiline text";
			case TBool:
				"A checkbox can be used to specify if the column is true or false";
			case TInt:
				"A integer number (which does not have fractional component)";
			case TFloat:
				"Any number";
			case TColor:
				"A numerical value that represents an RGB color";
			case TEnum(_):
				"An exclusive choice between a number of a given custom values. For example: Yes,No,Cancel,Error";
			case TFlags(_):
				"Several optional choices between a list of given custom values. For example: hasHat,hasShirt,hasShoes";
			case TRef(_):
				"A reference to another sheet row, using its unique idenfier";
			case TFile:
				"A relative or absolute path to a target file or image";
			case TImage:
				"An image to be displayed and stored in the database";
			case TTilePos:
				"A sub part of a tileset image";
			case TList:
				"A list of structured values";
			case TDynamic:
				"Any JSON data";
			case _:
				'No info for datatype $type';
		}
	}

}
