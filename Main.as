package  {
	import flash.display.*;
	import flash.events.*;
	
	public class Main extends Sprite {
		private const ROT_SPEED:uint=2;//скорость поворота  пушки в градусов/кадр
		private const R:uint=18;					//радиус Баблсов
		private var D:Number=R*Math.sqrt(3);
		private var cannon:cannon_mc;
		private var left:Boolean=false;
		private var right:Boolean=false;
		private var bubCont:Sprite;				//контейнер для отображения Баблсов
		private var bubble:bubble_mc;
		private const DEG_TO_RAD:Number=0.0174532925;// PI/180;
		private const BUBBLE_SPEED:uint=10;// скорость летящего Баблса в px/frame
		private var fire:Boolean=false;
		private var vx,vy:Number;
		private var fieldArray:Array;// массив представляющий поле
		private var chainArray:Array;//массив представляющий выиграшную цепочку
		private var connArray:Array;
		
		
		public function Main() {
			placeContainer();							//установка контейнера
			placeCannon();								// размещаем пушку на сцене
			loadBubble();									//заряжаем пушку
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKUp);
			addEventListener(Event.ENTER_FRAME, onEFrame);
		}
		
		private function placeCannon():void {
			cannon=new cannon_mc();
			addChild(cannon);
			cannon.y=450;
			cannon.x=R*8;
		}
		
		private function onKDown(e:KeyboardEvent):void {
		  switch (e.keyCode) {
			case 37 :
			  left=true;
			  break;
			case 39 :
			  right=true;
			  break;
			case 38 :
			if (!fire) {
				fire=true;
				var radians=(cannon.rotation-90)*DEG_TO_RAD;
				vx=BUBBLE_SPEED*Math.cos(radians);
        		vy=BUBBLE_SPEED*Math.sin(radians);
			}
			break;
		  }
		}
		
		private function onKUp (e:KeyboardEvent):void {
		  switch (e.keyCode) {
			case 37 :
			  left=false;
			  break;
			case 39 :
			  right=false;
			  break;
		  }
		}
		
		private function onEFrame(e:Event):void {
		  if (left) {
			cannon.rotation-=ROT_SPEED;
		  }
		  if (right) {
			cannon.rotation+=ROT_SPEED;
		  }
		  if (fire) {
			  bubble.x+=vx;
    		  bubble.y+=vy;
			  if (bubble.x<R) {
				  bubble.x=R;
				  vx*=-1;
			  }
			  if (bubble.x>R*15) {
				  bubble.x=R*15;
				  vx*=-1;
				}
				if (bubble.y<R) {
				  parkBubble();
				}else {
				  for (var i:uint = 0; i<bubCont.numChildren; i++) {
					var tmp:bubble_mc;
					tmp=bubCont.getChildAt(i) as bubble_mc;
					if (collide(tmp)) {
					  parkBubble();
					  break;
					}
				  }
				}
		  }
		}
		
		private function placeContainer():void {
			fieldArray = new Array();
		  bubCont=new Sprite();
		  addChild(bubCont);
		  bubCont.graphics.lineStyle(1,0xffffff,0.2);
		  for(var i:uint=0;i<11;i++){
			  fieldArray[i] = new Array();
			for(var j:uint=0;j<8;j++){
				if (i%2==0) {
					 bubCont.graphics.drawCircle(R+j*R*2,R+i*D,R);
					 fieldArray [i] [j] = 0;
				}else{
					if (j<7) {
						with (bubCont.graphics) {
							drawCircle(2*R+j*R*2,R+i*D,R);
							fieldArray [i] [j] = 0;
						 }
					}
				}
			 }
		  }
		}
		
		private function loadBubble():void {
			bubble = new bubble_mc();
			addChild(bubble);
			bubble.gotoAndStop(Math.floor(Math.random()*6))+1;
			bubble.x=R*8;
			bubble.y=450;
		}
		
		private function parkBubble():void  {
			  var row:uint=Math.floor(bubble.y/D);
 			  var col:uint;
			  if (row%2==0) {
				col=Math.floor(bubble.x/(R*2));
			  } else {
				col=Math.floor((bubble.x-R)/(R*2));
			  }
			  var placed_bubble:bubble_mc = new bubble_mc();
			  bubCont.addChild(placed_bubble);
			  if (row%2==0) {
				placed_bubble.x=(col*R*2)+R;
			  } else {
				placed_bubble.x=(col*R*2)+2*R;
			  }
			  placed_bubble.y=(row*D)+R;
			  placed_bubble.gotoAndStop(bubble.currentFrame);
			  placed_bubble.name=row+","+col;
			  fieldArray[row][col]=bubble.currentFrame;
			  chainArray=new Array();
			  getChain(row,col);
			  if (chainArray.length>2) {
			  for (var i:uint=0; i<chainArray.length; i++) {
				  with (bubCont) {
					removeChild(getChildByName(chainArray[i]));
				  }
				  var coords:Array=chainArray[i].split(",");
				  fieldArray[coords[0]][coords[1]]=0;
				}
				 removeNotConnected();
			  }
			  trace("chain: "+chainArray);
			  removeChild(bubble);
			  fire=false;
			  loadBubble();
		}
		
		private function collide(bub:bubble_mc):Boolean {
		  var dist_x:Number=bub.x-bubble.x;
		  var dist_y:Number=bub.y-bubble.y;
		  return Math.sqrt(dist_x*dist_x+dist_y*dist_y)<=2*R-4;
		}
		
		private function getValue(row:int,col:int):int {
			  if (fieldArray[row]==null) {
				return -1;
			  }
			  if (fieldArray[row][col]==null) {
				return -1;
			  }
			  return fieldArray[row][col];
			}
			
			private function isNewChain(row:int,col:int,val:uint):Boolean {
			  return val == getValue(row,col)&&chainArray.indexOf(row+","+col)==-
			1;
			}
			
			private function getChain(row:int,col:int):void {
			  chainArray.push(row+","+col);
			  var odd:uint=row%2;
			  var match:uint=fieldArray[row][col];
			  for (var i:int=-1; i<=1; i++) {
				for (var j:int=-1; j<=1; j++) {
				  if (i!=0||j!=0) {
					if (i==0||j==0||(j==-1&&odd==0)||(j==1&&odd==1)) {
					  if (isNewChain(row+i,col+j,match)) {
						getChain(row+i,col+j);
					  }
					}
				  }
				}
			  }
			}
			
			private function isNewConnection(row:int,col:int):Boolean {
			  return getValue(row,col)>0&&connArray.indexOf(row+","+col)==-1;
			}
			
			
			private function getConnections(row:int,col:int):void {
			  connArray.push(row+","+col);
			  var odd:uint=row%2;
			  for (var i:int=-1; i<=1; i++) {
				for (var j:int=-1; j<=1; j++) {
				  if (i!=0||j!=0) {
					if (i==0||j==0||(j==-1&&odd==0)||(j==1&&odd==1)) {
					  if (isNewConnection(row+i,col+j)) {
						if (row+i==0) {
						  connArray[0]="connected";
						} else {
						  getConnections(row+i,col+j);
						}
					  }
					}
				  }
				}
			  }
			}
			
			private function removeNotConnected():void {
			  for (var i:uint=1; i<11; i++) {
				for (var j:uint=0; j<8; j++) {
					 if (getValue(i,j)>0) {
						connArray=new Array();
						getConnections(i,j);
						if (connArray[0]!="connected") {
						  with (bubCont) {
							removeChild(getChildByName(i+"_"+j));
						  }
						  fieldArray[i][j]=0;
						}
					  }
					}
				 }
			}
				
	}
	
}
