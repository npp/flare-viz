package viz
{
	import flare.animate.Transitioner;
	import apps.App;
	import flare.data.DataField;
	import flare.data.DataSchema;
	import flare.data.DataSet;
	import flare.data.DataSource;
	import flare.data.DataUtil;
	import flare.display.RectSprite;
	import flare.display.TextSprite;
	import flare.query.methods.eq;
	import flare.query.methods.iff;
	import flare.scale.QuantitativeScale;
	import flare.scale.Scale;
	import flare.scale.ScaleType;
	import flare.util.Orientation;
	import flare.util.Shapes;
	import flare.util.Sort;
	import flare.util.Strings;
	import flare.util.palette.ColorPalette;
	import flare.vis.Visualization;
	import flare.vis.controls.ClickControl;
	import flare.vis.controls.HoverControl;
	import flare.vis.controls.TooltipControl;
	import flare.vis.data.Data;
	import flare.vis.data.DataSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.events.SelectionEvent;
	import flare.vis.events.TooltipEvent;
	import flare.vis.legend.Legend;
	import flare.vis.legend.LegendItem;
	import flare.vis.operator.encoder.ColorEncoder;
	import flare.vis.operator.filter.VisibilityFilter;
	import flare.vis.operator.label.StackedAreaLabeler;
	import flare.vis.operator.layout.StackedAreaLayout;
	import widgets.*;
	import util.ConsoleLog;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.filters.DropShadowFilter;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import info.BudgetCategory;
	
	[SWF(backgroundColor="#ffffff", frameRate="30")]
	public class TaxRevenue extends App
	{
		private var _bar:ProgressBar;
		private var _bounds:Rectangle;
		private var _boundsGraph:Rectangle;
		
		private var _vis:Visualization;
		private var _header:Sprite = new Sprite;
		private var _title:TextSprite;
		private var _intro:TextSprite;
		private var _directions:TextSprite;
		private var _button:Button;
		private var _footer:TextSprite;
		
		private var _c:ConsoleLog = new ConsoleLog();
			
		private var _fmtHeader:TextFormat = new TextFormat("Helvetica,Arial",16,0,true);
		private var _fmtFooter:TextFormat = new TextFormat("Helvetica,Arial",12,0x909090,false,true);
		private var _fmt:TextFormat = new TextFormat("Helvetica,Arial",14,0,false);
		private var _fmtLabel:TextFormat = new TextFormat("Helvetica,Arial",14,0,false);
		private var _fmtStackedAreaLabel:TextFormat = new TextFormat("Helvetica,Arial",14,0,false);
		private var _dur:Number = 1.25; // animation duration
		private var _t:Transitioner;
		private var _colTotals:Object = new Object();
		private var _query:Array = new Array();
		private var _filter:String = "All";
		private var _exact:Boolean = false;
		private var _cols:Array = new Array(); //will be populated with values that form the x-axis
		
		//a few vis-specific settings
		private var _normalize:Boolean = true;
		private var _url:String = "info/revenue-sources.txt";
		private var _colors:Array = [0xFF1B4C82, 0xFF2B6BB3, 0xFF5089C8,  0xFF80AFE3, 0xFFC6D9EF]; //dark to light
		
		private var _titleText:String =
			"Tax Revenue Sources, by percentage of total";
		private var _directionsText:String = 
			"Rollover chart to view annual percentages and amounts (adjusted to 2013 dollars).";
		private var _introText:String =
			"The primary sources of tax revenue have shifted over the years. Currently, individual income taxes and payroll taxes make up the majority of collections, with corporate income taxes a distant third.";
		private var _footerText:String = "source: " + 
			"<a href='http://www.whitehouse.gov/omb'>White House Office of Management and Budget</a>";
		
		protected override function init():void
		{
			addChild(_bar = new ProgressBar());
			_bar.bar.filters = [new DropShadowFilter(1)];
			
			var ds:DataSource = new DataSource(_url, "tab");
			var ldr:URLLoader = ds.load();
			
			ldr.addEventListener(Event.COMPLETE, function(evt:Event):void {
				var ds:DataSet = ldr.data as DataSet;
				for (var i:Number = 0; i < ds.nodes.data.length; i++) {
					_cols.push(ds.nodes.data[i].year);
				}
				_cols = unique(_cols).sort();
				var reshaped:Array = reshape(ds.nodes.data, ["category","sort"],
					"year", "amount", _cols, _normalize);
				var dr:Array = reshaped[0]; 	//data used for the viz
				_colTotals = reshaped[1];		//stash the total value for each column (for later use in tool top)
				visualize(Data.fromArray(dr));
			})
			
			
			_bar.loadURL(ldr, function():void {
				_bar = null;
			})
		}
		
		private function visualize(data:Data):void
		{
			// prepare data with default settings and sort
			data.nodes.sortBy("-data.sort");
			data.nodes.setProperties({
				shape: Shapes.POLYGON,
				lineColor: 0xFFFFFFFF,
				fillColor: 0xFF235D9C
			});
			
			// define the visualization
			_vis = new Visualization(data);
			
			// first, set the visibility according to the query
			_vis.operators.add(new VisibilityFilter(filter));
			_vis.operators[0].immediate = true; // filter immediately!
			
			// layout the stacked chart
			_vis.operators.add(new StackedAreaLayout(_cols,.08));
			if (_normalize) {
				_vis.operators[1].scale.labelFormat = "0.####%"; // show as percent
			}
			else {
				_vis.operators[1].scale.labelFormat = "$###,###,###,###,##0";
			}
			
			// label the stacks
			_vis.operators.add(new StackedAreaLabeler("data.category"));
			_vis.operators[2].threshold = 30;
			_vis.operators[2].columnIndex = 15;
			//_vis.operators[2].maxWidth = 150; //max width of stacked area labels
			//_fmtStackedAreaLabel.rightMargin = 50; //right margin of stacked area labels
			_vis.operators[2].textFormat = _fmtStackedAreaLabel
	
			// set the colors
		   var colorPalette:ColorPalette = new ColorPalette();
		   colorPalette.values = _colors;
			_vis.operators.add(new ColorEncoder("data.sort", "nodes", "fillColor", ScaleType.CATEGORIES, colorPalette));
		   
			// initialize y-axis labels: align
			_vis.xyAxes.yAxis.labelOffsetX = 50;  	// offset labels to the right
			//_vis.xyAxes.yAxis.showLines = false; 	// supress horizontal gridlines
			_vis.xyAxes.yAxis.lineCapX2 = 10; 		// extra line length to the right (only applies if gridlines are showing)
			_vis.xyAxes.showBorder = false;
			_vis.xyAxes.yAxis.labelTextFormat = _fmtLabel;
			
			//format x-axis labels
			_vis.xyAxes.xAxis.numLabels = 5 //_cols.length / 2;
	
			// place and update
			_vis.update();
			addChild(_vis);
			
			// add mouse-over highlight
			_vis.controls.add(new HoverControl(NodeSprite,
				// move highlighted node to be drawn on top
				HoverControl.MOVE_AND_RETURN,
				// highlight node to full saturation
				function(e:SelectionEvent):void {
					e.node.props.saturation = e.node.fillSaturation;
					e.node.fillSaturation = 1;
				},
				// return node to previous saturation
				function(e:SelectionEvent):void {
					e.node.fillSaturation = e.node.props.saturation;
				}
			));
			
			// add filter on click
			_vis.controls.add(new ClickControl(NodeSprite, 1,
				function(e:SelectionEvent):void {
					_exact = true; // force an exact search
					onFilter(e.node.data.category);
				}
			));
			
			// add tooltips
			_vis.controls.add(new TooltipControl(NodeSprite, null,
				// update on both roll-over and mouse-move
				updateTooltip, updateTooltip));
			
			// add titles, description, etc.
			addControls();
			layout();
		}
		
		private function updateTooltip(e:TooltipEvent):void
		{
			// get current year value from axes, and map to data
			var yr:Number = Number(
				_vis.xyAxes.xAxis.value(_vis.mouseX, _vis.mouseY));
			var year:String = (Math.round(yr)).toString();
			var def:Boolean = (e.node.data[year] != undefined);
			var toolTip:String;
			
			if (_normalize) {
				toolTip = Strings.format(
					"<b>{0} {1}</b><br/>"+(def?"${2:###,###,###,###,##0}<br/>":"<i>{2}</i><br/>")+(def?"{3:0.0%}":"<i>{3}</i>"),
					e.node.data.category,year, (def ? _colTotals[year] * e.node.data[year] : "Missing Data"),(def ? e.node.data[year] : "Missing Data"));
			}
			else {
				toolTip = Strings.format(
					"<b>{0} {1}</b><br/>"+(def?"${2:###,###,###,###,##0}<br/>":"<i>{2}</i><br/>")+(def?"{3:0.0%}":"<i>{3}</i>"),
					e.node.data.category,year, (def ? e.node.data[year] : "Missing Data"),(def ? e.node.data[year]/_colTotals[year] : "Missing Data"));
			}
			
			toolTip = toolTip + Strings.format("<br/><i>Click to isolate {0}</i>",e.node.data.category); 
			TextSprite(e.tooltip).htmlText = toolTip;
			
		}
		
		public override function resize(bounds:Rectangle):void
		{
			
			if (_bar) {
				_bar.x = bounds.width/2 - _bar.width/2;
				_bar.y = bounds.height/2 - _bar.height/2;
			}
			
			bounds.width -= (15 + 50);
			bounds.height -= (75 + 25);
			bounds.x += 15;
			bounds.y += 75;
			_bounds = bounds;
			
			//set _boundsGraph values to add padding between viz bounds and the stacked chart
			_boundsGraph = _bounds;
			_boundsGraph.height = _bounds.height - 35;
			
			layout();
		}
		
		private function layout():void
		{
			if (_vis) {
				// compute the visualization bounds
				_vis.bounds = _bounds;
				_vis.operators[1].layoutBounds = _boundsGraph;

				// update
				_footer.y = _boundsGraph.bottom + 30;
				_vis.update();
			}	
			
		}
		
		/** Filter function for determining visibility. */
		private function filter(d:DataSprite):Boolean
		{
			if (!_query || _query.length==0) {
				return true;
			} else {
				var s:String = String(d.data["category"]).toLowerCase();
				for each (var q:String in _query) {
					var len:int = q.length;
					if (len == 0) continue;
					if (!_exact && s.substr(0,len)==q) return true;
					if (_exact && q==s) return true;
				}
				return false;
			}
		}
		
		/** Callback for filter events. */
		private function onFilter(filterText:String=null):void
		{
			var headerContainer:DisplayObjectContainer = DisplayObjectContainer(getChildByName("header"));
			if (filterText != null) {
				_query[0] = filterText.toLowerCase().split(/\|/);
				headerContainer.getChildByName("showAllButton").visible = true;
			} else {
				_query = new Array();
				headerContainer.getChildByName("showAllButton").visible = false;
			}
			if (_t && _t.running) _t.stop();
			_t = _vis.update(_dur);
			_t.play();
			
			_exact = false; // reset exact match after each search
		}
		
		// --------------------------------------------------------------------
		
		private function addControls():void
		{			
			addChild(_header);
			_header.name = "header";
			
			// create title
			_title = new TextSprite("", _fmtHeader);
			_title.htmlText = _titleText;
			_header.addChild(_title);
			
			// create directions area
			_directions = new TextSprite("", _fmtFooter);
			_directions.y = _title.y + _title.height;
			_directions.htmlText = _directionsText;
			_header.addChild(_directions);
			
			_button = new Button('Show All',_fmt);
			_button.x = _directions.x + _directions.width + 15;
			_button.y = _directions.y - ((_button.height - _directions.height) / 2);
			_button.name = "showAllButton";
			_button.visible = (_query.length ? true : false);
			_button.buttonMode = true;
			_button.fillColor = 0xFFC5D3E2;
			_button.lineColor = 0xFF729AC8;
			_header.addChild(_button);
			_button.addEventListener(MouseEvent.CLICK,
				function(evt:MouseEvent):void { onFilter(); }
			);
			
			// create intro area
			_intro = new TextSprite("", _fmt);
			_intro.name = "introTextField";
			_intro.maxWidth = 600;
			_intro.y = _directions.y + _directions.height + 10;
			_intro.htmlText = _introText;
			_header.addChild(_intro);
			
			//create footer
			_footer = new TextSprite("", _fmtFooter);
			_footer.htmlText = _footerText;
			addChild(_footer);
			
		}
		
		// --------------------------------------------------------------------
		
		/**
		 * Reshapes a data set, pivoting from rows to columns. For example, if
		 * yearly data is stored in individual rows, this method can be used to
		 * map each year into a column and the full time series into a single
		 * row. This is often needed to use the stacked area layout.
		 * @param tuples an array of data tuples
		 * @param cats the category values to maintain
		 * @param dim the dimension upon which to pivot. The values of this
		 *  property should correspond to the names of newly created columns.
		 * @param measure the numerical value of interest. The values of this
		 *  property will be used as the values of the new columns.
		 * @param cols an ordered array of the new column names. These should
		 *  match the values of the <code>dim</code> property.
		 * @param normalize a flag indicating if the data should be normalized
		 */
		public static function reshape(tuples:Array, cats:Array, dim:String,
									   measure:String, cols:Array, normalize:Boolean=true):Array
		{
			var c:ConsoleLog = new ConsoleLog();
			var t:Object, d:Object, val:Object, name:String;
			var data:Array = [], names:Array = []
			var totals:Object = {};
			for each (val in cols) totals[val] = 0;
			
			// create data set
			for each (t in tuples) {
				// create lookup hash for tuple
				var hash:String = "";
				for each (name in cats) hash += t[name];
				
				if (names[hash] == null) {
					// create a new data tuple
					data.push(d = {});
					for each (name in cats) d[name] = t[name];
					d[t[dim]] = t[measure];
					names[hash] = d;
				} else {
					// update an existing data tuple
					names[hash][t[dim]] = t[measure];
				}
				totals[t[dim]] += t[measure];
			}
			// zero out missing data
			for each (t in data) {
				var max:Number = 0;
				for each (name in cols) {
					if (!t[name]) t[name] = 0; // zero out null entries
					if (normalize)
						t[name] /= totals[name]; // normalize
					if (t[name] > max) max = t[name];
				}
				t.max = max;
			}
			
			return [data,totals]
		}
		
		private function unique(arr:Array):Array {
			var hash:Object = {}, result:Array = [];
			for ( var i:Number = 0, l:Number = arr.length; i < l; ++i ) {
				if ( !hash.hasOwnProperty(arr[i]) ) {
					hash[ arr[i] ] = true;
					result.push(arr[i]);
				}
			}
			return result;
		}
		
		
	} // end of class TaxRevenue
}