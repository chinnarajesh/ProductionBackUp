/*!
 * jquery.fixedHeaderTable. The jQuery fixedHeaderTable plugin
 *
 * Copyright (c) 2011 Mark Malek
 * http://fixedheadertable.com
 *
 * Licensed under MIT
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * http://docs.jquery.com/Plugins/Authoring
 * jQuery authoring guidelines
 *
 * Launch  : October 2009
 * Version : 1.3
 * Released: May 9th, 2011
 *
 * 
 * all CSS sizing (width,height) is done in pixels (px)
 */

(function (j$) {

    j$.fn.fixedHeaderTable = function (method) {

        // plugin's default options
        var defaults = {
            
            width:          '100%',
            height:         '100%',
            themeClass:     'fht-default',
            borderCollapse:  true,
            fixedColumns:    0, // fixed first columns
            sortable:        false,
            autoShow:        true, // hide table after its created
            footer:          false, // show footer
            cloneHeadToFoot: false, // clone head and use as footer
            autoResize:      false, // resize table if its parent wrapper changes size
            create:          null // callback after plugin completes
        };

        var settings = {};

        // public methods
        var methods = {
            init: function (options) {
                settings = j$.extend({}, defaults, options);

                // iterate through all the DOM elements we are attaching the plugin to
                return this.each(function () {
                    var j$self = j$(this), // reference the jQuery version of the current DOM element
                    self = this; // reference to the actual DOM element
                    
                    if (helpers._isTable(j$self)) {
                        methods.setup.apply(this, Array.prototype.slice.call(arguments, 1));
                        j$.isFunction(settings.create) && settings.create.call(this);
                    } else {
			j$.error('Invalid table mark-up');
		    }
                });
            },
	    
	    /*
	     * Setup table structure for fixed headers and optional footer
	     */
            setup: function (options) {
                var j$self  = j$(this),
                self   = this,
                j$thead = j$self.find('thead'),
                j$tfoot = j$self.find('tfoot'),
                j$tbody = j$self.find('tbody'),
                j$wrapper,
                j$divHead,
                j$divFoot,
                j$divBody,
                j$fixedHeadRow,
                j$temp,
                tfootHeight = 0;
                
                settings.includePadding = helpers._isPaddingIncludedWithWidth();
                settings.scrollbarOffset = helpers._getScrollbarWidth();
		settings.themeClassName = settings.themeClass;
		
		if (settings.width.search('%') > -1) {
		    var widthMinusScrollbar = j$self.parent().width() - settings.scrollbarOffset;
		} else {
		    var widthMinusScrollbar = settings.width - settings.scrollbarOffset;				
		}
		
                j$self.css({
	            width: widthMinusScrollbar
	        });
	        

                if (!j$self.closest('.fht-table-wrapper').length) {
                    j$self.addClass('fht-table');
                    j$self.wrap('<div class="fht-table-wrapper"></div>');
                }

                j$wrapper = j$self.closest('.fht-table-wrapper');
                
                if (settings.fixedColumns > 0 && j$wrapper.find('.fht-fixed-column').length == 0) {
                    j$self.wrap('<div class="fht-fixed-body"></div>');
                    
                    var j$fixedColumns = j$('<div class="fht-fixed-column"></div>').prependTo(j$wrapper),
                    j$fixedBody	 = j$wrapper.find('.fht-fixed-body');
                }
                
                j$wrapper.css({
	            width: settings.width,
	            height: settings.height
	        })
	            .addClass(settings.themeClassName);

                if (!j$self.hasClass('fht-table-init')) {
                    
                    j$self.wrap('<div class="fht-tbody"></div>');
                    
                }
		j$divBody = j$self.closest('.fht-tbody');
		
                var tableProps = helpers._getTableProps(j$self);
                
                helpers._setupClone(j$divBody, tableProps.tbody);

                if (!j$self.hasClass('fht-table-init')) {
                    if (settings.fixedColumns > 0) {
                	j$divHead = j$('<div class="fht-thead"><table class="fht-table"></table></div>').prependTo(j$fixedBody);
                    } else {
                	j$divHead = j$('<div class="fht-thead"><table class="fht-table"></table></div>').prependTo(j$wrapper);
                    }
                    
                    j$thead.clone().appendTo(j$divHead.find('table'));
                } else {
                    j$divHead = j$wrapper.find('div.fht-thead');
                }

                helpers._setupClone(j$divHead, tableProps.thead);
                
                j$self.css({
                    'margin-top': -j$divHead.outerHeight(true)
                });
                
                /*
                 * Check for footer
                 * Setup footer if present
                 */
                if (settings.footer == true) {

                    helpers._setupTableFooter(j$self, self, tableProps);
                    
                    if (!j$tfoot.length) {
                	j$tfoot = j$wrapper.find('div.fht-tfoot table');
                    }
                    
                    tfootHeight = j$tfoot.outerHeight(true);
                }

                var tbodyHeight = j$wrapper.height() - j$thead.outerHeight(true) - tfootHeight - tableProps.border;
                
                j$divBody.css({
	            'height': tbodyHeight
	        });
                
                j$self.addClass('fht-table-init');
                
                if (typeof(settings.altClass) !== 'undefined') {
                    methods.altRows.apply(self);
                }
                
                if (settings.fixedColumns > 0) {
                    helpers._setupFixedColumn(j$self, self, tableProps);
                }
                
                if (!settings.autoShow) {
                    j$wrapper.hide();
                }
                
                helpers._bindScroll(j$divBody, tableProps);
                
                return self;
            },
            
            /*
             * Resize the table
             * Incomplete - not implemented yet
             */
            resize: function(options) {
            	var j$self = j$(this),
            	self  = this;
            	return self;
            },
            
            /*
             * Add CSS class to alternating rows
             */
            altRows: function(arg1) {
            	var j$self       = j$(this),
            	self            = this,
            	altClass        = (typeof(arg1) !== 'undefined') ? arg1 : settings.altClass;
            	
            	j$self.closest('.fht-table-wrapper')
            	    .find('tbody tr:odd:not(:hidden)')
            	    .addClass(altClass);
            },
            
            /*
             * Show a hidden fixedHeaderTable table
             */
            show: function(arg1, arg2, arg3) {
                var j$self		= j$(this),
                self  		= this,
                j$wrapper 	= j$self.closest('.fht-table-wrapper');

		// User provided show duration without a specific effect
                if (typeof(arg1) !== 'undefined' && typeof(arg1) === 'number') {
                    
                    j$wrapper.show(arg1, function() {
                	j$.isFunction(arg2) && arg2.call(this);
                    });

                    return self;
                    
                } else if (typeof(arg1) !== 'undefined' && typeof(arg1) === 'string'
                	    && typeof(arg2) !== 'undefined' && typeof(arg2) === 'number') {
		    // User provided show duration with an effect
		    
                    j$wrapper.show(arg1, arg2, function() {
                	j$.isFunction(arg3) && arg3.call(this);
                    });
                    
                    return self;
                    
                }
                
            	j$self.closest('.fht-table-wrapper')
                    .show();
                j$.isFunction(arg1) && arg1.call(this);
                
                return self;
            },
            
            /*
             * Hide a fixedHeaderTable table
             */
            hide: function(arg1, arg2, arg3) {
                var j$self 		= j$(this),
                self		= this,
                j$wrapper 	= j$self.closest('.fht-table-wrapper');
                
                // User provided show duration without a specific effect
                if (typeof(arg1) !== 'undefined' && typeof(arg1) === 'number') {
                    j$wrapper.hide(arg1, function() {
                	j$.isFunction(arg3) && arg3.call(this);
                    });
                    
                    return self;
                } else if (typeof(arg1) !== 'undefined' && typeof(arg1) === 'string'
                	    && typeof(arg2) !== 'undefined' && typeof(arg2) === 'number') {

                    j$wrapper.hide(arg1, arg2, function() {
                	j$.isFunction(arg3) && arg3.call(this);
                    });
                    
                    return self;
                }
                
                j$self.closest('.fht-table-wrapper')
                    .hide();
                
                j$.isFunction(arg3) && arg3.call(this);
                
                
                
                return self;
            },
            
            /*
             * Destory fixedHeaderTable and return table to original state
             */
            destroy: function() {
                var j$self    = j$(this),
                self     = this,
                j$wrapper = j$self.closest('.fht-table-wrapper');
                
                j$self.insertBefore(j$wrapper)
                    .removeAttr('style')
                    .append(j$wrapper.find('tfoot'))
                    .removeClass('fht-table fht-table-init')
                    .find('.fht-cell')
                    .remove();
                
                j$wrapper.remove();
                
                return self;
            }

        }

        // private methods
        var helpers = {

	    /*
	     * return boolean
	     * True if a thead and tbody exist.
	     */
            _isTable: function(j$obj) {
                var j$self = j$obj,
                hasTable = j$self.is('table'),
                hasThead = j$self.find('thead').length > 0,
                hasTbody = j$self.find('tbody').length > 0;

                if (hasTable && hasThead && hasTbody) {
                    return true;
                }
                
                return false;

            },
            
            /*
             * return void
             * bind scroll event
             */
            _bindScroll: function(j$obj, tableProps) {
            	var j$self = j$obj,
            	j$wrapper = j$self.closest('.fht-table-wrapper'),
            	j$thead = j$self.siblings('.fht-thead'),
            	j$tfoot = j$self.siblings('.fht-tfoot');
            	
            	j$self.bind('scroll', function() {
            	    if (settings.fixedColumns > 0) {
            	        var j$fixedColumns = j$wrapper.find('.fht-fixed-column');
            	        
            	        j$fixedColumns.find('.fht-tbody table')
            	            .css({
            	                'margin-top': -j$self.scrollTop()
            	            });
            	    }
            	    
            	    j$thead.find('table')
            		.css({
            		    'margin-left': -this.scrollLeft
            		});
            	    
            	    if (settings.cloneHeadToFoot) {
            		j$tfoot.find('table')
	            	    .css({
	            		'margin-left': -this.scrollLeft
	            	    });
            	    }
            	});
            },
            
            /*
             * return void
             */
            _fixHeightWithCss: function (j$obj, tableProps) {
            	if (settings.includePadding) {
	            j$obj.css({
	            	'height': j$obj.height() + tableProps.border
	            });
            	} else {
            	    j$obj.css({
            		'height': j$obj.parent().height() + tableProps.border
            	    });
            	}
            },
            
            /*
             * return void
             */
            _fixWidthWithCss: function(j$obj, tableProps, width) {
            	if (settings.includePadding) {
            	    j$obj.each(function(index) {
			j$(this).css({
            		    'width': width == undefined ? j$(this).width() + tableProps.border : width + tableProps.border
			});
            	    }); 
            	} else {
            	    j$obj.each(function(index) {
			j$(this).css({
            		    'width': width == undefined ? j$(this).parent().width() + tableProps.border : width + tableProps.border
			});
            	    });
            	}

            },
            
            /*
             * return void
             */
						_setupFixedColumn: function ( j$obj, obj, tableProps ) {
		            var j$self           = j$obj,
		                self            = obj,
		                j$wrapper        = j$self.closest('.fht-table-wrapper'),
		                j$fixedBody      = j$wrapper.find('.fht-fixed-body'),
		                j$fixedColumn    = j$wrapper.find('.fht-fixed-column'),
		                j$thead          = j$('<div class="fht-thead"><table class="fht-table"><thead></thead></table></div>'),
		                //j$thead            = j$('<div class="fht-thead"><table class="fht-table"><thead><tr></tr></thead></table></div>'),
		                j$tbody          = j$('<div class="fht-tbody"><table class="fht-table"><tbody></tbody></table></div>'),
		                j$tfoot          = j$('<div class="fht-tfoot"><table class="fht-table"><thead><tr></tr></thead></table></div>'),
		                j$firstThChildren   = j$fixedBody.find('.fht-thead thead tr th:first-child'),
		                //j$firstThChild   = j$fixedBody.find('.fht-thead thead tr:first-child th:first-child'),
		                j$firstTdChildren,
		                fixedColumnWidth = 0,
		                //fixedColumnWidth = j$firstThChild.outerWidth(true) + tableProps.border,
		                fixedBodyWidth  = j$wrapper.width(),
		                fixedBodyHeight = j$fixedBody.find('.fht-tbody').height() - settings.scrollbarOffset,
		                j$newRow;
		
		            j$firstThChildren.each( function() {
		                var columnWidth = j$(this).outerWidth(true) + tableProps.border;
		                fixedColumnWidth = fixedColumnWidth>columnWidth ? fixedColumnWidth : columnWidth;
		            });
		
		            // Fix cell heights
		            j$firstThChildren.each( function() {
		                helpers._fixHeightWithCss( j$(this), tableProps );
		                helpers._fixWidthWithCss( j$(this), tableProps );
		            });
		            /**
		            helpers._fixHeightWithCss( j$firstThChild, tableProps );
		            helpers._fixWidthWithCss( j$firstThChild, tableProps );
		            **/
		            j$firstTdChildren = j$fixedBody.find('tbody tr td:first-child')
		                .each( function(index) {
		                    helpers._fixHeightWithCss( j$(this), tableProps );
		                    helpers._fixWidthWithCss( j$(this), tableProps );
		                });
		
		            // clone header
		            j$thead.appendTo(j$fixedColumn)
		            j$firstThChildren.each(function(index) {
		                j$newRow = j$('<tr></tr>').appendTo(j$thead.find('thead'));
		                j$(this).clone()
		                    .appendTo(j$newRow);
		            });
		            /*
		            j$thead.appendTo(j$fixedColumn)
		                .find('tr')
		                .append(j$firstThChild.clone());
		            */
		
		            j$tbody.appendTo(j$fixedColumn)
		                .css({
//		                    'margin-top': -1,
		                    'height': fixedBodyHeight + tableProps.border
		                });
		            j$firstTdChildren.each(function(index) {
		                j$newRow = j$('<tr></tr>').appendTo(j$tbody.find('tbody'));
		
		                if ( settings.altClass && j$(this).parent().hasClass(settings.altClass) ) {
		                    j$newRow.addClass(settings.altClass);
		                } 
		
		                j$(this).clone()
		                    .appendTo(j$newRow);
		            });
		
		            // set width of fixed column wrapper
		            j$fixedColumn.css({
		                'width': fixedColumnWidth
		            });
		
		            // set width of body table wrapper
		            j$fixedBody.css({
		                'width': fixedBodyWidth
		            });
		
		            // setup clone footer with fixed column
		            if ( settings.footer == true || settings.cloneHeadToFoot == true ) {
		                var j$firstTdFootChild = j$fixedBody.find('.fht-tfoot thead tr th:first-child');
		
		                helpers._fixHeightWithCss( j$firstTdFootChild, tableProps );
		                j$tfoot.appendTo(j$fixedColumn)
		                    .find('tr')
		                    .append(j$firstTdFootChild.clone());
		                j$tfoot.css({
		                    'top': settings.scrollbarOffset
		                });
		            }
		        },            
            /*
             * return void
             */
            _setupTableFooter: function (j$obj, obj, tableProps) {
            	
            	var j$self 		= j$obj,
            	self  		= obj,
            	j$wrapper 	= j$self.closest('.fht-table-wrapper'),
            	j$tfoot		= j$self.find('tfoot'),
            	j$divFoot	= j$wrapper.find('div.fht-tfoot');
            	
            	if (!j$divFoot.length) {
            	    if (settings.fixedColumns > 0) {
            		j$divFoot = j$('<div class="fht-tfoot"><table class="fht-table"></table></div>').appendTo(j$wrapper.find('.fht-fixed-body'));
            	    } else {
            		j$divFoot = j$('<div class="fht-tfoot"><table class="fht-table"></table></div>').appendTo(j$wrapper);
            	    }
            	}

            	switch (true) {
            	case !j$tfoot.length && settings.cloneHeadToFoot == true && settings.footer == true:
            	    
            	    var j$divHead = j$wrapper.find('div.fht-thead');
            	    
            	    j$divFoot.empty();
            	    j$divHead.find('table')
            		.clone()
            		.appendTo(j$divFoot);
            	    
            	    break;
            	case j$tfoot.length && settings.cloneHeadToFoot == false && settings.footer == true:
            	    
            	    j$divFoot.find('table')
            		.append(j$tfoot)
	                .css({
	                    'margin-top': -tableProps.border
	                });
            	    
            	    helpers._setupClone(j$divFoot, tableProps.tfoot);
            	    
            	    break;
            	}
            	
            },
            
            /*
             * return object
             * Widths of each thead cell and tbody cell for the first rows.
             * Used in fixing widths for the fixed header and optional footer.
             */
            _getTableProps: function(j$obj) {
                var tableProp = {
                    thead: {},
                    tbody: {},
                    tfoot: {},
                    border: 0
                },
                borderCollapse = 1;
                
                if (settings.borderCollapse == true) {
                    borderCollapse = 2;
                }
		
		tableProp.border = (j$obj.find('th:first-child').outerWidth() - j$obj.find('th:first-child').innerWidth()) / borderCollapse;
		
                j$obj.find('thead tr:first-child th').each(function(index) {
                    tableProp.thead[index] = j$(this).width() + tableProp.border;
                });
                
                j$obj.find('tfoot tr:first-child td').each(function(index) {
                    tableProp.tfoot[index] = j$(this).width() + tableProp.border;
                });
                
                j$obj.find('tbody tr:first-child td').each(function(index) {
                    tableProp.tbody[index] = j$(this).width() + tableProp.border;
                });

                return tableProp;
            },
            
            /*
             * return void
             * Fix widths of each cell in the first row of obj.
             */
            _setupClone: function(j$obj, cellArray) {
                var j$self    = j$obj,
                selector = (j$self.find('thead').length) ?
                    'thead th' : 
                    (j$self.find('tfoot').length) ?
                    'tfoot td' :
                    'tbody td',
                j$cell;
                
                j$self.find(selector).each(function(index) {
                    j$cell = (j$(this).find('div.fht-cell').length) ? j$(this).find('div.fht-cell') : j$('<div class="fht-cell"></div>').appendTo(j$(this));
		    
                    j$cell.css({
                        'width': parseInt(cellArray[index])
                    });
                    
                    /*
                     * Fixed Header and Footer should extend the full width
                     * to align with the scrollbar of the body 
                     */
                    if (!j$(this).closest('.fht-tbody').length && j$(this).is(':last-child') && !j$(this).closest('.fht-fixed-column').length) {
                    	var padding = ((j$(this).innerWidth() - j$(this).width()) / 2) + settings.scrollbarOffset;
                    	j$(this).css({
                    	    'padding-right': padding + 'px'
                    	});
                    }
                });
            },
            
            /*
             * return boolean
             * Determine how the browser calculates fixed widths with padding for tables
             * true if width = padding + width
             * false if width = width
             */
            _isPaddingIncludedWithWidth: function() {
            	var j$obj 			= j$('<table class="fht-table"><tr><td style="padding: 10px; font-size: 10px;">test</td></tr></table>'),
            	defaultHeight,
            	newHeight;
            	
            	j$obj.appendTo('body');
            	
            	defaultHeight = j$obj.find('td').height();
            	
            	j$obj.find('td')
            	    .css('height', j$obj.find('tr').height());
            	
            	newHeight = j$obj.find('td').height();
            	j$obj.remove();

            	if (defaultHeight != newHeight) {
            	    return true;
            	} else {
            	    return false;
            	}
            	
            },
            
            /*
             * return int
             * get the width of the browsers scroll bar
             */
            _getScrollbarWidth: function() {
            	var scrollbarWidth = 0;
            	
            	if (!scrollbarWidth) {
		    if (j$.browser.msie) {
			var j$textarea1 = j$('<textarea cols="10" rows="2"></textarea>')
			    .css({ position: 'absolute', top: -1000, left: -1000 }).appendTo('body'),
			j$textarea2 = j$('<textarea cols="10" rows="2" style="overflow: hidden;"></textarea>')
			    .css({ position: 'absolute', top: -1000, left: -1000 }).appendTo('body');
			scrollbarWidth = j$textarea1.width() - j$textarea2.width() + 2; // + 2 for border offset
			j$textarea1.add(j$textarea2).remove();
		    } else {
			var j$div = j$('<div />')
			    .css({ width: 100, height: 100, overflow: 'auto', position: 'absolute', top: -1000, left: -1000 })
			    .prependTo('body').append('<div />').find('div')
			    .css({ width: '100%', height: 200 });
			scrollbarWidth = 100 - j$div.width();
			j$div.parent().remove();
		    }
		}
		
		return scrollbarWidth;
            }

        }


        // if a method as the given argument exists
        if (methods[method]) {

            // call the respective method
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));

            // if an object is given as method OR nothing is given as argument
        } else if (typeof method === 'object' || !method) {

            // call the initialization method
            return methods.init.apply(this, arguments);

            // otherwise
        } else {

            // trigger an error
            j$.error('Method "' +  method + '" does not exist in fixedHeaderTable plugin!');

        }

    };

})(jQuery);