/***
	hellovis-touch.js
***/

// prevent scrolling:
document.ontouchmove = function(event){
    event.preventDefault();
}

console.log("hello vis!");

var width = 320;
var height = 460;

var jitter = 0.5;

var collisionPadding = 4;
var minCollisionRadius = 12;

// set up svg
var svg = d3.select('body').append('svg')
	.attr('width', width)
	.attr('height', height);

var nodes = [
	{ size: 20 },
	{ size: 25 },
	{ size: 18 },
	{ size: 20 },
	{ size: 25 },
	{ size: 18 },
	{ size: 40 },
	{ size: 25 },
	{ size: 48 },
	{ size: 20 },
	{ size: 25 },
	{ size: 18 },
	{ size: 40 },
	{ size: 20 },
	{ size: 25 },
	{ size: 18 },
	{ size: 20 }
];

var collide = function(jitter){
	return function(d){
      nodes.forEach(function(d2){
        if(d != d2){
	    	var x = d.x - d2.x;
          	var y = d.y - d2.y;
          	var distance = Math.sqrt(x * x + y * y);
	        var minDistance = d.size + d2.size + collisionPadding;

	        if(distance < minDistance){
	        	var distance = (distance - minDistance) / distance * jitter;
            	var moveX = x * distance;
            	var moveY = y * distance;
            	d.x -= moveX;
            	d.y -= moveY;
            	d2.x += moveX;
            	d2.y += moveY;
        	}
        }
    });
    };
};

var tick = function(e){
	node.each(collide(jitter));

	node.attr('cx', function(d){ return d.x; })
		.attr('cy', function(d){ return d.y; });
};

// set-up force-directed layout
var force = d3.layout.force()
	.nodes(nodes)
	.gravity(0.1)
	.size([width, height])
	.on('tick', tick);

force.start();

var color = d3.scale.category20();

var node = svg.selectAll('circle')
	.data(force.nodes())
	.enter().append('circle')
	.attr('r', function(d){ return d.size; })
	.style('fill', function(d,i){ return color(i); })
	.call(force.drag)
