package ui.modal.panel;

class EditSheetDefs extends ui.modal.Panel {
	var curSheet:Null<cdb.Sheet>;
	public var tabulator:Null<Tabulator>;
	public var sheetDefsForm:Null<SheetDefsForm>;
	var inspectionView = true;

	public function new() {
		super();

		// Main page
		linkToButton("button.editSheets");
		loadTemplate("editSheetDefs");

		// Create a new table
		jContent.find("button.createSheet").click(function(ev) {
			var getName = (i) -> i == 0 ? "Sheet" : 'Sheet${i + 1}';
			var i = 0;
			while (project.database.getSheet(getName(i)) != null) {
				i++;
			}
			project.database.createSheet(getName(i));
			updateSheetList();
			updateSheetForm();
			// editor.ge.emit(TableDefAdded(td));
		});

		// History
		jContent.find("button.undo").click(ev -> {
			if (tabulator == null)
				return;
			tabulator.tabulator.undo();
		});
		jContent.find("button.redo").click(ev -> {
			if (tabulator == null)
				return;
			tabulator.tabulator.redo();
		});

		// Refresh view on view change
		var jButton = jContent.find("input[id='inspectionView']");
		var i = Input.linkToHtmlInput(inspectionView, jButton);
		jButton.change(e -> {
			selectSheet(curSheet);
		});

		// Import
		jContent.find("button.import").click(ev -> {
			var ctx = new ContextMenu(ev);
			ctx.addAction({
				label: L.t._("CDB - Import a CastleDB database"),
				subText: L.t._('WARNING!!! Will rewrite current database'),
				cb: () -> {
					dn.js.ElectronDialogs.openFile([".cdb"], project.getProjectDir(), function(absPath:String) {
						absPath = StringTools.replace(absPath, "\\", "/");
						switch dn.FilePath.extractExtension(absPath, true) {
							case "cdb":
								var i = new importer.CastleDb();
								i.load(project.makeRelativeFilePath(absPath));
								updateSheetList();
							case _:
								N.error('The file must have the ".cdb" extension.');
						}
					});
				},
			});
			ctx.addAction({
				label: L.t._("CSV - Import Sheet"),
				subText: L.t._('Expected format:\n - One entry per line\n - Fields separated by commas'),
				cb: () -> {
					dn.js.ElectronDialogs.openFile([".csv"], project.getProjectDir(), function(absPath:String) {
						absPath = StringTools.replace(absPath, "\\", "/");
						switch dn.FilePath.extractExtension(absPath, true) {
							case "csv":
								var s = misc.CastleWrapper.importSheet("TODO", absPath);
								selectSheet(s);
							case _:
								N.error('The file must have the ".csv" extension.');
						}
					});
				},
			});
		});
		if (project.database == null)
			return;

		if (project.database.sheets.length > 0) {
			selectSheet(project.database.sheets[0]);
			return;
		}
		updateSheetList();
		updateSheetForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		// super.onGlobalEvent(e);
		// switch e {
		// 	case TableDefAdded(td), TableDefChanged(td):
		// 		selectSheet(td);

		// 	case TableDefRemoved(td):
		// 		selectSheet(project.defs.tables[0]);

		// 	case _:
		// }
	}

	function updateSheetForm() {
		var jTabForm = jContent.find("dl.sheetForm");

		if (curSheet == null) {
			jTabForm.hide();
			return;
		}
		jTabForm.show();

		// Input.linkToHtmlInput(curSheet.name, jTabForm.find("input[name='name']") );
		// i.linkEvent(TableDefChanged(curTable));

		// var jSel = jContent.find("#primaryKey");
		// for (column in curTable.columns) {
		// 	jSel.append('<option>'+ column +'</option>');
		// }
		// var i = Input.linkToHtmlInput(curTable.primaryKey, jTabForm.find("select[name='primaryKey']") );
		// i.linkEvent(TableDefChanged(curTable));
		// var i = Input.linkToHtmlInput(tableView, jTabForm.find("input[id='tableView']") );
		// i.linkEvent(TableDefChanged(curTable));
	}

	public function selectSheet(sheet:cdb.Sheet) {
		curSheet = sheet;
		updateSheetList();
		updateSheetForm();

		var i = jContent.find("input[name=name]");
		i.off();
		i.val(sheet.name);
		i.on("blur", (e) -> {
			sheet.rename(i.val());
			Notification.success("Sheet renamed");
			updateSheetList();
		});

		var jTabEditor = jContent.find("#sheetEditor");
		if (tabulator != null)
			tabulator.tabulator.destroy();
		jTabEditor.empty();

		if (inspectionView) {
			sheetDefsForm = new ui.SheetDefsForm(curSheet);
			jTabEditor.append(sheetDefsForm.jWrapper);
		} else {
			tabulator = new Tabulator("#sheetEditor", curSheet);
			// var tableDefsForm = new ui.TableDefsForm(curTable);
			// jTabEditor.append(tableDefsForm.jWrapper);
		}
	}

	function deleteSheet(sheet:cdb.Sheet) {
		new LastChance(L.t._("Sheet ::name:: deleted", {name: sheet.name}), project);
		sheet.base.deleteSheet(sheet);
		if (project.database.sheets.length > 0) {
			selectSheet(project.database.sheets[0]);
		}
	}

	function updateSheetList() {
		var jList = jContent.find(".sheetList>ul");
		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul class="niceList compact"/>');
		jSubList.appendTo(jLi);

		for (sheet in project.database.sheets.filter((x) -> !x.props.hide)) {
			var jLi = new J("<li class='draggable'/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">' + sheet.name + '</span>');
			// jLi.data("uid",td.uid);

			if (sheet == curSheet)
				jLi.addClass("active");
			jLi.click(function(_) {
				selectSheet(sheet);
			});

			ContextMenu.attachTo(jLi, [
				// {
				// 	label: L._Copy(),
				// 	cb: ()->App.ME.clipboard.copyData(CTilesetDef, td.toJson()),
				// 	enable: ()->!td.isUsingEmbedAtlas(),
				// },
				// {
				// 	label: L._Cut(),
				// 	cb: ()->{
				// 		App.ME.clipboard.copyData(CTilesetDef, td.toJson());
				// 		deleteTilesetDef(td);
				// 	},
				// 	enable: ()->!td.isUsingEmbedAtlas(),
				// },
				// {
				// 	label: L._PasteAfter(),
				// 	cb: ()->{
				// 		var copy = project.defs.pasteTilesetDef(App.ME.clipboard, td);
				// 		editor.ge.emit( TilesetDefAdded(copy) );
				// 		selectTileset(copy);
				// 	},
				// 	enable: ()->App.ME.clipboard.is(CTilesetDef),
				// },
				// {
				// 	label: L._Duplicate(),
				// 	cb: ()-> {
				// 		var copy = project.defs.duplicateTilesetDef(td);
				// 		editor.ge.emit( TilesetDefAdded(copy) );
				// 		selectTileset(copy);
				// 	},
				// 	enable: ()->!td.isUsingEmbedAtlas(),
				// },
				{
					label: L._Delete(),
					cb: deleteSheet.bind(sheet),
				},
			]);
		}

		// Make list sortable
		JsTools.makeSortable(jSubList, function(ev) {
			// var jItem = new J(ev.item);
			// var fromIdx = project.defs.getTableIndex( jItem.data("uid") );
			// var toIdx = ev.newIndex>ev.oldIndex
			// 	? jItem.prev().length==0 ? 0 : project.defs.getTableIndex( jItem.prev().data("uid") )
			// 	: jItem.next().length==0 ? project.defs.tables.length-1 : project.defs.getTableIndex( jItem.next().data("uid") );

			// var moved = project.defs.sortTableDef(fromIdx, toIdx);
			// selectSheet(moved);
			// editor.ge.emit(TilesetDefSorted);
		});
	}
}
