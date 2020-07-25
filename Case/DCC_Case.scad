// ************************************************
// DCC-Booster Case
// by Dave Flynn
// Filename: DCC_Case.scad
// Created: 7/2/2020
// Version: 1.0b2 7/24/2020
// Units: mm
// ************************************************
//  ***** History *****
// 1.0b2 7/24/2020 Shorter bolt bosses on top cover.
// 1.0b1 7/2/2020 First code
// ************************************************
//  ***** for STL Output *****
// CaseBottom(ShowPCB=false);
// rotate([180,0,0]) CaseTop();
// ************************************************

include<CommonStuffSAEmm.scad>

$fn=$preview? 24:90;
Overlap=0.05;
IDXtra=0.2;

PCB_x=103;
PCB_y=99.5;
PCB_z=1.8;
PCB_Parts_h=31;
PCB_Extra=1;

HoleInset=5.08;

Ledge_h=1.2;
CaseWall_t=2.5;
CaseBot_t=3;
CaseTop_t=CaseBot_t;
BaseWall_h=13;

Case_X=PCB_x+CaseWall_t*2+PCB_Extra;
Case_Y=PCB_y+CaseWall_t*2+PCB_Extra;
Basement_h=3;

module RoundRect(X=20,Y=20,Z=10,R=2){
	hull(){
		translate([-X/2+R,-Y/2+R,0]) cylinder(r=R,h=Z);
		translate([-X/2+R,Y/2-R,0]) cylinder(r=R,h=Z);
		translate([X/2-R,-Y/2+R,0]) cylinder(r=R,h=Z);
		translate([X/2-R,Y/2-R,0]) cylinder(r=R,h=Z);
	} // hull
} // RoundRect

module FaceHoles(IsBottom=true){
	PCB_Top_z=CaseBot_t+Basement_h+PCB_z;
	
	RJ9_Size_y=23.5;
	RJ9_Size_z=IsBottom==true? 20:13.0;
	RJ9_y=11; // from PCB corner
	
	SW1_Size_y=16;
	SW1_Size_z=IsBottom==true? 20:8.5;
	SW1_y=36.2;
	
	LED_Size_y=11;
	LED_Size_z=IsBottom==true? 20:18.5;
	LED_y=51.5;

	J1_Size_y=22;
	J1_Size_z=IsBottom==true? 20:11;
	J1_y=65;

	if (IsBottom==true){
		translate([-Case_X/2-Overlap,-PCB_y/2+RJ9_y,PCB_Top_z]) cube([CaseWall_t+Overlap*2,75.5,20]);
	}else{
//*
	// RJ-9s
	translate([-Case_X/2-Overlap,-PCB_y/2+RJ9_y,PCB_Top_z]) cube([CaseWall_t+Overlap*2,RJ9_Size_y,RJ9_Size_z]);
	// SW1
	translate([-Case_X/2-Overlap,-PCB_y/2+SW1_y,PCB_Top_z]) cube([CaseWall_t+Overlap*2,SW1_Size_y,SW1_Size_z]);
	// LED
	translate([-Case_X/2-Overlap,-PCB_y/2+LED_y,PCB_Top_z]) cube([CaseWall_t+Overlap*2,LED_Size_y,LED_Size_z]);
	// J1
	translate([-Case_X/2-Overlap,-PCB_y/2+J1_y,PCB_Top_z]) cube([CaseWall_t+Overlap*2,J1_Size_y,J1_Size_z]);
	/**/
	}
	
} // FaceHoles



module CaseTop(){
	Top_h=CaseTop_t+PCB_Parts_h+Ledge_h-BaseWall_h;
	
	/*
	// Back mount???
	SideMount_t=5;
	SideMount_h=12;
	
	if (HasMount==true) difference(){
		union(){
		hull(){
			translate([Case_X/2-CaseWall_t-1,Case_Y/2-CaseWall_t-1,Top_h-SideMount_h]){
				cylinder(d=SideMount_t,h=SideMount_h);
				translate([20,10,0]) cylinder(d=SideMount_t,h=SideMount_h);
				
			} 
		} // hull
		hull(){
			translate([Case_X/2-CaseWall_t-1,Case_Y/2-CaseWall_t-1,Top_h-SideMount_h]){
				
				translate([20,10,0]) cylinder(d=SideMount_t,h=SideMount_h);
				translate([20,10+SideMount_h,0]) cylinder(d=SideMount_t,h=SideMount_h);
			} 
		} // hull
		} // union
		
		translate([Case_X/2-CaseWall_t-1,Case_Y/2-CaseWall_t-1,Top_h-SideMount_h/2]) translate([20-3,10+SideMount_h/2+2.5,0]) rotate([0,-90,0]) Bolt6ClearHole();
	} // difference
	/**/
	
	difference(){
		RoundRect(X=Case_X,Y=Case_Y,Z=Top_h,R=CaseWall_t+1);
		
		translate([0,0,-(CaseBot_t+Basement_h+PCB_z+BaseWall_h-Ledge_h)]) FaceHoles(IsBottom=false);
		
		// inside
		translate([0,0,-Overlap]) RoundRect(X=Case_X-CaseWall_t*2,Y=Case_Y-CaseWall_t*2,Z=Top_h-CaseTop_t,R=1);
		
		// Ledge
		translate([0,0,-Overlap]) RoundRect(X=Case_X-CaseWall_t,Y=Case_Y-CaseWall_t,Z=Ledge_h,R=1+CaseWall_t/2);
		
		// Heat sinc
		translate([PCB_x/2,-PCB_y/2+56,-Overlap]) cube([10,26.5,Top_h-CaseTop_t]);
		
		// PCB mounting holes
		translate([-PCB_x/2+HoleInset,-PCB_y/2+HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
		translate([-PCB_x/2+HoleInset,PCB_y/2-HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
		translate([PCB_x/2-HoleInset,-PCB_y/2+HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
		translate([PCB_x/2-HoleInset,PCB_y/2-HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
	} // difference
	
	difference(){
		union(){
			
			//connect bolt bosses to corner
			hull(){
				translate([-PCB_x/2+HoleInset,-PCB_y/2+HoleInset,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				translate([-Case_X/2+CaseWall_t/2+1.5,-Case_Y/2+CaseWall_t/2+1.5,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				}
			hull(){
				translate([PCB_x/2-HoleInset,-PCB_y/2+HoleInset,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				translate([Case_X/2-CaseWall_t/2-1.5,-Case_Y/2+CaseWall_t/2+1.5,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				}
			hull(){
				translate([-PCB_x/2+HoleInset,PCB_y/2-HoleInset,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				translate([-Case_X/2+CaseWall_t/2+1.5,Case_Y/2-CaseWall_t/2-1.5,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				}
			hull(){
				translate([PCB_x/2-HoleInset,PCB_y/2-HoleInset,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				translate([Case_X/2-CaseWall_t/2-1.5,Case_Y/2-CaseWall_t/2-1.5,Ledge_h]) cylinder(d=3,h=Top_h-Ledge_h);
				}
				
			// Bolt bosses
			translate([-PCB_x/2+HoleInset,-PCB_y/2+HoleInset,-BaseWall_h+Ledge_h/2]) cylinder(d=10,h=Top_h+BaseWall_h-Ledge_h/2);
			translate([-PCB_x/2+HoleInset,PCB_y/2-HoleInset,-BaseWall_h+Ledge_h/2]) cylinder(d=10,h=Top_h+BaseWall_h-Ledge_h/2);
			translate([PCB_x/2-HoleInset,-PCB_y/2+HoleInset,-BaseWall_h+Ledge_h/2]) cylinder(d=10,h=Top_h+BaseWall_h-Ledge_h/2);
			translate([PCB_x/2-HoleInset,PCB_y/2-HoleInset,-BaseWall_h+Ledge_h/2]) cylinder(d=10,h=Top_h+BaseWall_h-Ledge_h/2);
		}
		
		// PCB mounting holes
		translate([-PCB_x/2+HoleInset,-PCB_y/2+HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
		translate([-PCB_x/2+HoleInset,PCB_y/2-HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
		translate([PCB_x/2-HoleInset,-PCB_y/2+HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
		translate([PCB_x/2-HoleInset,PCB_y/2-HoleInset,-BaseWall_h+10]) Bolt4HeadHole(depth=8,lHead=30);
	} // difference
} // CaseTop

//translate([0,0,CaseBot_t+Basement_h+PCB_z+BaseWall_h-Ledge_h+Overlap])CaseTop();
//CaseBottom(ShowPCB=true);

module CaseBottom(ShowPCB=true){
	
	
	Ear_x=12;
	Ear_y=12;
	Ear_h=5;
	
	Base_h=CaseBot_t+Basement_h+PCB_z+BaseWall_h;
	
	difference(){
		union(){
			RoundRect(X=Case_X,Y=Case_Y,Z=Base_h,R=CaseWall_t+1);
			
			// Mount Ears, Base mounting
			translate([Case_X/2-Ear_x/2-4,0,0]) RoundRect(X=Ear_x,Y=Case_Y+Ear_y*2,Z=Ear_h,R=Ear_x/2);
			translate([-Case_X/2+Ear_x/2+4,0,0]) RoundRect(X=Ear_x,Y=Case_Y+Ear_y*2,Z=Ear_h,R=Ear_x/2);
		} // union
		
		// inside
		translate([0,0,CaseBot_t]) RoundRect(X=Case_X-CaseWall_t*2,Y=Case_Y-CaseWall_t*2,Z=Base_h,R=1);
		
		// ledge
		difference(){
			translate([0,0,Base_h-Ledge_h]) RoundRect(X=Case_X+2,Y=Case_Y+2,Z=3,R=1);
			translate([0,0,Base_h-Ledge_h-Overlap]) RoundRect(X=Case_X-CaseWall_t,Y=Case_Y-CaseWall_t,Z=4,R=1+CaseWall_t/2);
		} // difference
		
		FaceHoles();
		
		// Heat sinc
		translate([PCB_x/2,-PCB_y/2+56,CaseBot_t+Basement_h]) cube([10,26.5,20]);
		
		// PCB mounting holes
		translate([-PCB_x/2+HoleInset,-PCB_y/2+HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		translate([-PCB_x/2+HoleInset,PCB_y/2-HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		translate([PCB_x/2-HoleInset,-PCB_y/2+HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		translate([PCB_x/2-HoleInset,PCB_y/2-HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		
		// Case mounting holes, Base mounting
		translate([Case_X/2-Ear_x/2-4,Case_Y/2+Ear_y/2,Ear_h]) Bolt6ClearHole();
		translate([Case_X/2-Ear_x/2-4,-Case_Y/2-Ear_y/2,Ear_h]) Bolt6ClearHole();
		translate([-Case_X/2+Ear_x/2+4,Case_Y/2+Ear_y/2,Ear_h]) Bolt6ClearHole();
		translate([-Case_X/2+Ear_x/2+4,-Case_Y/2-Ear_y/2,Ear_h]) Bolt6ClearHole();
	} // difference
	
	// PCB Mounting
	difference(){
		union(){
			translate([-PCB_x/2+HoleInset-1,-PCB_y/2+HoleInset-1,0])
				RoundRect(X=HoleInset*2,Y=HoleInset*2,Z=CaseBot_t+Basement_h,R=1);
			translate([-PCB_x/2+HoleInset-1,PCB_y/2-HoleInset+1,0])
				RoundRect(X=HoleInset*2,Y=HoleInset*2,Z=CaseBot_t+Basement_h,R=1);
			translate([PCB_x/2-HoleInset+1,-PCB_y/2+HoleInset-1,0])
				RoundRect(X=HoleInset*2,Y=HoleInset*2,Z=CaseBot_t+Basement_h,R=1);
			translate([PCB_x/2-HoleInset+1,PCB_y/2-HoleInset+1,0])
				RoundRect(X=HoleInset*2,Y=HoleInset*2,Z=CaseBot_t+Basement_h,R=1);
		} // union
		
		// PCB mounting holes
		translate([-PCB_x/2+HoleInset,-PCB_y/2+HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		translate([-PCB_x/2+HoleInset,PCB_y/2-HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		translate([PCB_x/2-HoleInset,-PCB_y/2+HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
		translate([PCB_x/2-HoleInset,PCB_y/2-HoleInset,CaseBot_t+Basement_h]) Bolt4Hole();
	} // difference
	
	if ($preview==true && ShowPCB==true) translate([0,0,CaseBot_t+Basement_h]) color("Blue") RoundRect(X=PCB_x,Y=PCB_y,Z=PCB_z,R=Overlap);
} // CaseBottom

//CaseBottom(ShowPCB=false);







































