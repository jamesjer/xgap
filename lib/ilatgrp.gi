#############################################################################
##
#W  ilatgrp.gi                 	XGAP library                  Max Neunhoeffer
##
#H  @(#)$Id: ilatgrp.gi,v 1.7 1999/01/14 19:53:29 gap Exp $
##
#Y  Copyright 1998,       Max Neunhoeffer,              Aachen,       Germany
##
##  This file contains the implementations for graphs and posets
##
Revision.pkg_xgap_lib_ilatgrp_gi :=
    "@(#)$Id: ilatgrp.gi,v 1.7 1999/01/14 19:53:29 gap Exp $";


#############################################################################
##
##  Representations:  
##
#############################################################################
  
  
#############################################################################
##
#R  IsGraphicSubgroupLattice . . . . . .  repr. for graphic subgroup lattices
##
if not IsBound(IsGraphicSubgroupLattice) then
  DeclareRepresentation( "IsGraphicSubgroupLattice",
    IsComponentObjectRep and IsAttributeStoringRep and IsGraphicSheet and
    IsGraphicSheetRep and IsGraphicGraphRep and IsGraphicPosetRep,
# we inherit those components from the sheet:        
    [ "name", "width", "height", "gapMenu", "callbackName", "callbackFunc",
      "menus", "objects", "free",
# and the following from being a poset:
      "levels",           # list of levels, stores current total ordering
      "levelparams",      # list of level parameters
      "selectedvertices", # list of selected vertices
      "menutypes",        # one entry per menu which contains list of types
      "menuenabled",      # one entry per menu which contains list of flags
      "rightclickfunction",    # the current function which is called when
                               # user clicks right button
      "color",            # some color infos for the case of different models
      "levelboxes",       # little graphic boxes for the user to handle levels
      "showlevels",       # flag, if levelboxes are shown
# now follow our own components:
      "group",            # the group
      "limits",           # a record with some limits, e.g. "conjugates"
      "menuoperations",   # configuration of menu operations
      "infodisplays",     # list of records for info displays, see below
      "largestlabel",     # largest used number for label
      "lastresult",       # list of vertices which are "green"
      "largestinflevel",  # largest used number for infinity-level
      "selector"],        # the current text selector or "false"
    IsGraphicSheet );
fi;


#############################################################################
##
##  Configuration section for menu operations and info displays:
##
#############################################################################

#############################################################################
##
##  Some global constants for configuration purposes (see "ilatgrp.gi"):
##
#############################################################################

BindGlobal( "GGLfrom1", 1 );
BindGlobal( "GGLfrom2", 2 );
BindGlobal( "GGLfromSet", 3 );
BindGlobal( "GGLto0", 0 );
BindGlobal( "GGLto1", 1 );
BindGlobal( "GGLtoSet", 2 );
BindGlobal( "GGLwhereUp", 1 );
BindGlobal( "GGLwhereDown", 2 );
BindGlobal( "GGLwhereAny", 0 );
BindGlobal( "GGLwhereBetween", 3 );
BindGlobal( "GGLrelsMax", 1 );
BindGlobal( "GGLrelsTotal", 2 );
BindGlobal( "GGLrelsNo", 0 );
BindGlobal( "GGLrelsDown", 3 );
BindGlobal( "GGLrelsUp", 4 );


##
##  The configuration of the menu operations works as follows:
##  Every menu operation gets a record with the following entries, which
##  can take on the values described after the colon respectively:
##
##   name     : a string
##   op       : a GAP-Operation for group(s)
##   sheet    : true, false
##   parent   : true, false
##   from     : GGLfrom1, GGLfrom2, GGLfromSet
##   to       : GGLto0, GGLto1, GGLtoSet
##   where    : GGLwhereUp, GGLwhereDown, GGLwhereAny, GGLWhereBetween
##   plural   : true, false
##   rels     : GGLrelsMax, GGLrelsTotal, GGLrelsNo, GGLrelsDown, GGLrelsup
##
##  Please use always these names instead of actual values because the values
##  of these variables can be subject to changes, especially because they
##  actually should be integers rather than strings.
##
##  <name> is the name appearing in the menu and info messages.
##  <op> is called to do the real work. The usage of <op> is however configured
##  by the other entries. <from> says, how many groups <op> gets as parameters.
##  It can be one group, exactly two or a list (GGLfromSet) of groups.
##  <sheet> says, if the graphic sheet is supplied as first parameter.
##  <parent> says, if the parent group is supplied as first/second parameter of
##  the call of the operation or not.
##  <to> says, how many groups <op> produces, it can be zero, one or a list
##  of groups (GGLtoSet). <where> determines what is known about the relative
##  position of the new groups with respect to the input groups of <op>.
##  GGLwhereUp means, that the new group(s) all contain all groups <op> was
##  called with. GGLwhereDown means, that the new group(s) are all contained
##  in all groups <op> was called with. GGLwhereAny means that nothing is
##  known about the result(s) with respect to this question. GGLwhereBetween
##  applies only for the case <from>=GGLfrom2 and means, that all produced
##  groups are contained in the first group and contain the second group
##  delivered to <op>. That means that in case such an operation exists
##  it will be checked before the call to the operation, which group is
##  contained in the other! It is an error if that is not the case!
##  <plural> is a flag which determines, if more than the
##  appropriate number of vertices can be selected. In this case <op> is called
##  for all subsets of the set of selected subgroups with the right number of
##  groups. This does not happen if <plural> is false. <rels> gives <op> the
##  possibility to return inclusion information about the newly calculated
##  subgroups. If <rels> is GGLrelsMax or GGLrelsTotal then <op> must return
##  a record with components `subgroups' which is a list of subgroups 
##  generated as well as a component `inclusions' which lists all maximality
##  inclusions among these subgroups.
##  A maximality inclusion is given as a list `[<i>,<j>]' indicating that
##  subgroup number <i> is a maximal subgroup of subgroup number <j>, the
##  numbers 0 and 1+length(`subgroups') are used to denote <U> and <G>
##  respectively, this applies to the case <rels>=GGLrelsMax.
##  In the case <rels>=GGLrelsTotal each pair says that the first group is
##  contained in the second. 
##  Again: The complete poset information must be returned!
##  In the case <rels>=GGLrelsNo nothing is known about the relative inclusions
##  of the results. <op> just returns a list of groups. If <rels>=GGLrelsDown
##  then the returned list is a descending chain and if <rels>=GGLrelsUp then
##  the returned list is an ascending chain.
##  If the record component "givesconjugates" is bound to true, then all
##  new vertices are put in the same class as the input vertex, so this
##  only makes sense for <from>=GGLfrom1. It is also only necessary for
##  those group types, where we don't have CanCompareSubgroups.


##  we have two cases up to now:
BindGlobal( "GGLMenuOpsForFiniteGroups",
        [ rec( name := "All Subgroups", 
               op := function(G) 
                 local result,cl;
                 result := [];
                 for cl in LatticeSubgroups(G)!.conjugacyClassesSubgroups do
                   Append(result,AsList(cl));
                 od;
                 return result;
               end,
               parent := false, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereDown, plural := false, rels := GGLrelsNo ),
          rec( name := "Centralizers", op := Centralizer, 
               parent := true, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereAny, plural := true, rels := GGLrelsNo ),
          rec( name := "Centres", op := Centre, 
               parent := false, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "Closure", op := ClosureGroup, 
               parent := false, from := GGLfromSet, to := GGLto1, 
               where := GGLwhereUp, plural := false, rels := GGLrelsNo ),
          rec( name := "Closures", op := ClosureGroup, 
               parent := false, from := GGLfrom2, to := GGLto1, 
               where := GGLwhereUp, plural := true, rels := GGLrelsNo ),
          rec( name := "Commutator Subgroups", op := CommutatorSubgroup,
               parent := false, from := GGLfrom2, to := GGLto1, 
               where := GGLwhereAny, plural := true, rels := GGLrelsNo ),
          rec( name := "Conjugate Subgroups", 
#FIXME: again use ConjugateSubgroups???
               op := function(G,H) 
                       return AsList(ConjugacyClassSubgroups(G,H)); 
                     end,
               parent := true, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereAny, plural := true, rels := GGLrelsNo ),
          rec( name := "Cores", op := Core,
               parent := true, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "DerivedSeries", op := DerivedSeriesOfGroup,
               parent := false, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereDown, plural := true, rels := GGLrelsDown ),
          rec( name := "DerivedSubgroups", op := DerivedSubgroup,
               parent := false, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "Fitting Subgroups", op := FittingSubgroup,
               parent := false, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "Intermediate Subgroups", op := IntermediateSubgroups,
               parent := false, from := GGLfrom2, to := GGLtoSet, 
               where := GGLwhereBetween, plural := false, rels := GGLrelsMax),
          rec( name := "Intersection", op := Intersection,
               parent := false, from := GGLfromSet, to := GGLto1, 
               where := GGLwhereDown, plural := false, rels := GGLrelsNo ),
          rec( name := "Intersections", op := Intersection,
               parent := false, from := GGLfrom2, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "Normalizers", op := Normalizer,
               parent := true, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereUp, plural := true, rels := GGLrelsNo ),
          rec( name := "Normal Closures", op := NormalClosure,
               parent := true, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereUp, plural := true, rels := GGLrelsNo ),
          rec( name := "Normal Subgroups", op := NormalSubgroups,
               parent := false, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "Sylow Subgroups", op := GGLSylowSubgroup,
               parent := false, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo )
] );
                                             
BindGlobal( "GGLMenuOpsForFpGroups",
        [ rec( name := "Abelian Prime Quotient", op := GGLAbelianPQuotient,
               parent := false, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := false, rels := GGLrelsNo ),
          rec( name := "All Overgroups", op := IntermediateSubgroups,
               parent := true, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereUp, plural := false, rels := GGLrelsMax ),
          rec( name := "Conjugacy Class", 
#FIXME: again use ConjugateSubgroups???
               op := function(G,H) 
                       return AsList(ConjugacyClassSubgroups(G,H)); 
                     end,
               parent := true, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereAny, plural := false, rels := GGLrelsNo,
               givesconjugates := true ),
          rec( name := "Cores", op := Core,
               parent := true, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "DerivedSubgroups", op := DerivedSubgroup,
               parent := false, from := GGLfrom1, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ),
          rec( name := "Epimorphisms", op := GGLEpimorphisms,
               parent := false, from := GGLfrom1, to := GGLtoSet, 
               where := GGLwhereDown, plural := false, rels := GGLrelsNo ),
          rec( name := "Intersections", op := Intersection,
               parent := false, from := GGLfrom2, to := GGLto1, 
               where := GGLwhereDown, plural := true, rels := GGLrelsNo ) 
        ] );
# FIXME: ... to be continued


##
##  The configuration of the info displays works as follows:
##  Info displays come in two flavours:
##   (1) info about an attribute
##   (2) info from a function
##  The reason for (2) is that it could be interesting to see "relative"
##  information about a subgroup with respect to the parent group. This
##  cannot be an attribute because it does not belong to the group itself.
##  Every info display gets a record with the following components:
##   name      : a string
##   tostr     : a function (can be "String") which converts the value to 
##               display into a string, if not bound "String" is taken
##  For case (1) we only have one more component:
##   attrib    : an attribute or property (the gap operation)
##  For case (2) we have:
##   func      : a function which returns the value that should be displayed
##   sheet     : true iff first parameter for <func> should be the sheet
##   parent    : true iff first/second parameter should be the parent group
##  if one of the last two is not bound it counts like "false".
##  The information produced by the functions "func" is cached in the record
##  "info" of the "data" part of the vertex under the component "name".
##
BindGlobal( "GGLInfoDisplaysForFiniteGroups",
        [ rec( name := "Size", attrib := Size ),
          rec( name := "Index", func := Index, parent := true ),
          rec( name := "IsAbelian", attrib := IsCommutative ),
          rec( name := "IsCentral", func := IsCentral, parent := true ),
          rec( name := "IsCyclic", attrib := IsCyclic ),
          rec( name := "IsNilpotent", attrib := IsNilpotentGroup ),
          rec( name := "IsNormal", func := IsNormal, parent := true ),
          rec( name := "IsPerfect", attrib := IsPerfectGroup ),
          rec( name := "IsSimple", attrib := IsSimpleGroup ),
          rec( name := "IsSolvable", attrib := IsSolvableGroup ),
          rec( name := "Isomorphism", attrib := IdGroup ) 
        ] );
                 
BindGlobal( "GGLInfoDisplaysForFpGroups",
        [ rec( name := "Index", func := Index, parent := true ),
          rec( name := "IsNormal", func := IsNormal, parent := true ),
          rec( name := "AbelianInvariants", attrib := AbelianInvariants ),
          rec( name := "Presentation", func := GGLPresentation ) 
        ] );
# FIXME: ... to be continued


#############################################################################
##
##  Global data, menus etc.:  
##
#############################################################################
  

#############################################################################
##
##  Menu entries and Popups:
##
#############################################################################


############################################################################
##
#M  GGLRightClickPopup . . . . . . . . . . called if user does a right click
##
##  This is called if the user does a right click on a vertex or somewhere
##  else on the sheet. This operation is highly configurable with respect
##  to the Attributes of groups it can display/calculate. See the 
##  configuration section in "ilatgrp.gi" for an explanation.
##
InstallMethod( GGLRightClickPopup,
    "for a graphic subgroup lattice, a vertex, and two integers",
    true,
    [ IsGraphicSheet and IsGraphicSubgroupLattice, IsGPVertex, IsInt, IsInt ],
    0,

function(sheet,v,x,y)
  local   grp,  textselectfunc,  text,  i,  str,  funcclose,  funcall;
  
  # did we get a vertex?
  if v = fail then
    return;
  fi;
  
    # destroy other text selectors flying around
  if sheet!.selector <> false then
    Close(sheet!.selector);
    sheet!.selector := false;
  fi;
  
  # get the group of <obj>
  grp := v!.data.group;

  # text select function
  textselectfunc := function( sel, name )
    local   tid,  current,  text,  str,  value,  parameters;
    
    tid  := sel!.selected;
    current := sheet!.infodisplays[tid];
    text := ShallowCopy(sel!.labels);
    # FIXME: If String behaves properly
    str  := ShallowCopy(String( current.name, -14 ));
    if IsBound(current.attrib) then
      value := current.attrib( grp );
    else
      if not(IsBound(v!.data.info.(current.name))) then
        # we have to calculate:
        parameters := [];
        if IsBound(current.sheet) and current.sheet then 
          Add(parameters,sheet);
        fi;
        if IsBound(current.parent) and current.parent then 
          Add(parameters,sheet!.group);
        fi;
        Add(parameters,grp);
        value := CallFuncList(current.func,parameters);
        v!.data.info.(current.name) := value;
      else
        # we know "by heart"
        value := v!.data.info.(current.name);
      fi;
    fi;
    if IsBound(current.tostr) then
      Append(str,current.tostr(value));
    else
      Append(str,String(value));
    fi;
    text[tid] := str;
    Relabel( sel, text );
    return true;
  end;

  # construct the string in the first place:
  text := [];
  for i in sheet!.infodisplays  do
    # FIXME: if behaviour of String is OK
    str := ShallowCopy(String( i.name, -14 ));
    # do we know the value?
    if IsBound(i.attrib) then
      if Tester(i.attrib)(grp) then
        if IsBound(i.tostr) then
          Append(str,i.tostr(i.attrib(grp)));
        else
          Append(str,String(i.attrib(grp)));
        fi;
      else
        Append(str,"Unknown");
      fi;
    else   #  its determined by a function and perhaps cached:
      if IsBound(v!.data.info.(i.name)) then
        if IsBound(i.tostr) then
          Append( str, i.tostrv(v!.data.info.(i.name)));
        else
          Append( str, String(v!.data.info.(i.name)));
        fi;
      else
        Append( str, "Unknown" );
      fi;
    fi;
    Add( text, str );
    Add( text, textselectfunc );
  od;

  # button select functions:
  funcclose := function( sel, bt )
    Close(sel);
    sheet!.selector := false;
    return true;  
  end;
  funcall := function( sel, bt )
    local i;
    for i  in [ 1 .. Length(sel!.labels) ]  do
      sel!.selected := i;
      sel!.textFuncs[i]( sel, sel!.labels[i] );
    od;
    Enable( sel, "all", false );
    return true;  
  end;
  
  # construct text selector
  sheet!.selector := TextSelector(
        Concatenation( " Information about ", v!.label ),
        text,
        [ "all", funcall, "close", funcclose ] );

end);


#############################################################################
##
##  Methods for menu actions:
##
#############################################################################


##
## we need some dialogs:
##
BindGlobal( "GGLPrimeDialog", Dialog( "OKcancel", "Prime" ) );
BindGlobal( "GGLGoOnDialog", Dialog( "OKcancel", "Go on?" ) );


#############################################################################
##
#M  GGLMenuOperation . . . . . . . . . . . . . . . .  is called from the menu
##
##  This operation is called for all so called "menu operations" the user
##  wants to perform on lattices. It is highly configurable with respect
##  to the input and output and the GAP-Operation which is actually performed
##  on the selected subgroups. See the configuration section in "ilatgrp.gi"
##  for an explanation.
##
InstallMethod( GGLMenuOperation,
    "for a graphic subgroup lattice, a menu, and a string",
    true,
    [ IsGraphicSheet and IsGraphicSubgroupLattice, IsMenu, IsString ],
    0,

function(sheet, menu, entry)
  local   menuop,  parameters,  selected,  v,  todolist,  i,  j,  todo,  
          currentparameters,  result,  infostr,  vertices,  newflag,  len,  
          hints,  grp,  res,  ver,  T,  inc,  T2;
  
  # first we determine the menu entry which was selected:
  menuop := Position(menu!.entries,entry);
  # fail is not an option here!
  menuop := sheet!.menuoperations[menuop];
  
  # note that we are guaranteed to have enough vertices selected!
  
  # let's prepare the parameters:
  parameters := [];
  if IsBound(menuop.sheet) and menuop.sheet then 
    Add(parameters,sheet); 
  fi;
  if IsBound(menuop.parent) and menuop.parent then 
    Add(parameters,sheet!.group); 
  fi;
  
  # the selected vertices:
  selected := Selected(sheet);
  
  # we clear old "results":
  for v in sheet!.lastresult do
    if PositionSet(selected,v) = fail then
      Recolor(sheet,v,sheet!.color.unselected);
    else
      Recolor(sheet,v,sheet!.color.selected);
    fi;
  od;
  sheet!.lastresult := [];
    
  if menuop.from = GGLfrom1 then
    # we do *not* have to look for menuop.plural because if it is false
    # then there can only be one vertex selected!
    todolist := List(selected,v->[v]);
    
  elif menuop.from = GGLfrom2 then
    # we do *not* have to look for menuop.plural because if it is false
    # then there can only be selected exactly two vertices.
    todolist := [];
    for i in [1..Length(selected)-1] do
      for j in [i+1..Length(selected)] do
        Add(todolist,[selected[i],selected[j]]);
      od;
    od;
    
  else  # menuop.from = GGLfromSet then
    # we do *not* have to look for menuop.plural because it is forbidden
    # for this case!
    todolist := [selected];
  fi;
  
  for todo in [1..Length(todolist)] do
    currentparameters := ShallowCopy(parameters);
    
    # there is one special case where we have to compare the two groups
    # in question:
    if menuop.from = GGLfrom2 and menuop.where = GGLwhereBetween then
      if not IsSubgroup( todolist[todo][1]!.data.group, 
                         todolist[todo][2]!.data.group ) then
        todolist[todo]{[1,2]} := todolist[todo]{[2,1]};
      fi;
    fi;
    
    Append(currentparameters,List(todolist[todo],v->v!.data.group));
    result := CallFuncList(menuop.op,currentparameters);
    
    # we give some information:
    infostr := Concatenation(menuop.name," (",todolist[todo][1]!.label);
    for i in [2..Length(todolist[todo])] do
      Append(infostr,",");
      Append(infostr,todolist[todo][i]!.label);
    od;
    Append(infostr,")");
    
    # now we have either nothing or a group or a list of groups or a record 
    # with components "subgroups" and "inclusions".
    if result = fail then
      Append(infostr," --> fail");
      Info(GraphicLattice,1,infostr);
      infostr := "";
      if Query( GGLGoOnDialog ) = false then
        Info(GraphicLattice,1,"...Aborted.");
        return;
      fi;
    fi;
    if menuop.to = GGLto0 or result = fail then
      if result <> fail then
        Info(GraphicLattice,1,infostr);
        infostr := "";
      fi;
    else
      
      Append(infostr," --> (");
      
      if menuop.to = GGLto1 then
        result := [result];
      fi;
      
      if IsList(result) then
        result := rec(subgroups := result, inclusions := []);
      fi;
      
      # first we only insert the "new" vertices:
      vertices := [];
      newflag := [];
      len := Length(result.subgroups);
      hints := List(todolist[todo],v->v!.x);
      for grp in [1..len] do
        # we want no lines to vanish:
        FastUpdate(sheet,false);
        if IsBound(menuop.givesconjugates) and
           menuop.givesconjugates then
          res := InsertVertex( sheet, result.subgroups[grp], 
                               todolist[todo][1],hints );
        else
          res := InsertVertex( sheet, result.subgroups[grp], false, hints );
        fi;
        FastUpdate(sheet,true);
        
        vertices[grp] := res[1];
        newflag[grp] := res[2];
        
        # we mark the vertex:
        Select(sheet,res[1],true);
        if sheet!.color.result <> false  then
          Recolor( sheet, res[1], sheet!.color.result );
        fi;

        if grp <> 1 then
          Append(infostr,",");
        fi;
        Append(infostr,vertices[grp]!.label);
      od;
      Append(infostr,")");
      Info(GraphicLattice,1,infostr);
      infostr := "";
      
      # if the sheet has the HasseProperty, we are done, because the 
      # connections are calculated. Otherwise we have to see what we can do.
      if not HasseProperty(sheet) then
        # do we have additional information?
        if menuop.rels = GGLrelsTotal then
          # we calculate the info which vertex is maximal in which:
          T := List([1..len],x->List([1..len],y->0));
          for inc in result.inclusions do
            T[inc[1]][inc[2]] := 1;
          od;
          T2 := T * T;
          # if there is a value <> 0 at the position (i,j) then there is a
          # possibility to walk in two steps from vertex i to vertex j
          for i in [1..len] do
            for j in [1..len] do
              if T[i][j] <> 0 and T2[i][j] = 0 then
                NewInclusionInfo( sheet, vertices[i], vertices[j] );
              fi;
            od;
          od;
        elif menuop.rels = GGLrelsMax then
          for inc in result.inclusions do
            if inc[1] >= 1 and inc[1] <= len and 
               inc[2] >= 1 and inc[2] <= len then
                # this is no inclusion with lower or higher groups!
              NewInclusionInfo( sheet, vertices[inc[1]], vertices[inc[2]] );
            fi;
          od;
        elif menuop.rels = GGLrelsDown then
          for i in [1..len-1] do
            NewInclusionInfo( sheet, vertices[i+1], vertices[i] );
          od;
        elif menuop.rels = GGLrelsUp then
          for i in [1..len-1] do
            NewInclusionInfo( sheet, vertices[i], vertices[i+1] );
          od;
        fi;
        # we cannot say anything if menuop.rels = GGLrelsNo
        
        # perhaps we have information about the selected groups:
        if menuop.where = GGLwhereUp then
          for i in [1..len] do
            for j in [1..Length(todolist[todo])] do
              NewInclusionInfo( sheet, todolist[todo][j], vertices[i] );
            od;
          od;
        elif menuop.where = GGLwhereDown then
          for i in [1..len] do
            for j in [1..Length(todolist[todo])] do
              NewInclusionInfo( sheet, vertices[i], todolist[todo][j] );
            od;
          od;
        elif menuop.where = GGLwhereBetween then
          for i in [1..len] do
            NewInclusionInfo( sheet, vertices[i], todolist[todo][1] );
            NewInclusionInfo( sheet, todolist[todo][2], vertices[i] );
          od;
        fi;
        # we cannot say anything if menuop.where = GGLwhereAny
      fi;     # not HasseProperty
    fi;  # operation produced something
  od;  # all done
end);


#############################################################################
##
#M  GGLSylowSubgroup(<grp>)  . . . . . .  asks for prime, calls SylowSubgroup
##
##  This operation just asks for a prime by a little dialog and calls then
##  SylowSubgroup. Returns its result.
##
InstallMethod( GGLSylowSubgroup,
    "for a group",
    true,
    [ IsGroup ],
    0,

function(grp)
  local   res,  p;
  res := Query( GGLPrimeDialog );
  if res = false then
    return fail;
  fi;
  p := Int(res);
  if not IsInt(p) or not IsPrime(p) then
    return fail;
  fi;
  return SylowSubgroup( grp, p );
end);


#############################################################################
##
##  Methods for inserting new vertices:
##
#############################################################################


#############################################################################
##
#M  InsertVertex( <sheet>, <grp>, <conj>, <hints> ) . . . . insert new vertex
##
##  Insert the group <grp> as a new vertex into the sheet. If 
##  CanCompareSubgroups is set for the lattice, we check, if the group is
##  already in the lattice or if we already have a conjugate subgroup.
##  If the lattice has the HasseProperty, then this new vertex is sorted 
##  into the poset. So we check for all vertices on higher levels, if
##  the new vertex is contained and for all vertices on lower levels,
##  if they are contained in the new vertex. We try then to add edges to
##  the appropriate vertices. If the lattice does not have the HasseProperty,
##  nothing is done with respect to the connections of any vertex.
##  Returns list with vertex as first entry and a flag as second, which 
##  says, if this vertex was inserted right now or has already been there.
##  <hint> is a list of x coordinates which should give some hint for the
##  choice of the new x coordinate. It can for example be the x coordinates
##  of those groups which were parameter for the operation which calculated
##  the group. <hints> can be empty but must always be a list!
##  If the lattice does not have CanCompareSubgroups and <conj> is a vertex
##  we put the new vertex into the class of this vertex. Otherwise <conj>
##  should either be false or fail.
##
InstallMethod( InsertVertex,
    "for a graphic subgroup lattice, a group, and a list",
    true,
    [ IsGraphicSubgroupLattice, IsGroup, IsObject, IsList ],
    0,
        
function( sheet, grp, conjugclass, hints )
  local   index,  data,  newlevel,  str,  vertex,  v,  vers,  lev,  cl,  
          conj,  Walkup,  Walkdown,  containerlist,  containedlist;
  
  ## FIXME: what if this index calculation crashes?
  ## so we never get infinite indices!??
  ## we have to add code to determine Size if that is possible!
  
  index := Index(sheet!.group,grp);
  data := rec(group := grp,
              isClassRep := false,
              info := rec(Index := index));
  # missing: class and classrep, isClassRep could be changed!
  
  # do we have this level yet?
  # FIXME: what if index is infinite?
  if index = infinity then
    sheet!.largestinflevel := sheet!.largestinflevel + 1;
    newlevel := [infinity,sheet!.largestinflevel];
  else
    newlevel := index;
  fi;
  
  if Position(Levels(sheet),newlevel) = fail then
    if IsInt(newlevel) then
      if newlevel < 0 then
        str := "Size ";
        Append(str,String(-newlevel));
      else
        str := "Index ";
        Append(str,String(newlevel));
      fi;
    else
      str := String(newlevel);
    fi;
    CreateLevel(sheet,newlevel,str);
  fi;
  
  vertex := false;   # will become the new vertex
  if CanCompareSubgroups(sheet) then
    # we search for this group:
    v := WhichVertex(sheet,grp,function(data,vdata) 
                                 return data=vdata.group; 
                               end);
    if v <> fail then      
      return( [v,false] );
    fi;
    
    # perhaps we have a conjugate group?
    vers := [];
    lev := Position( Levels(sheet), newlevel );
    lev := sheet!.levels[lev];
    # we walk through all classes and search the class representative:
    for cl in lev!.classes do
      Add(vers,First(cl,x->x!.data.isClassRep));
    od;
    
    if Length(vers) = 0 then 
      conj := fail;
    else
      conj := First([1..Length(vers)],
                    v->IsConjugate(sheet!.group,grp,vers[v]!.data.group));
    fi;
    
    if conj <> fail then
      # we insert into that class
      
      sheet!.largestlabel := sheet!.largestlabel+1;
      data.classRep := vers[conj]!.data;
      data.class := vers[conj]!.data.class;
      vertex := Vertex(sheet,data,rec(levelparam := newlevel,
                                      classparam := lev!.classparams[conj],
                                      label := String(sheet!.largestlabel)));
    fi;
  fi;
  
  # if not yet done we create a new vertex in a new class:
  if vertex = false then
    data.isClassRep := true;
    data.classRep := data;
    data.class := [data];
    sheet!.largestlabel := sheet!.largestlabel + 1;
    if IsGPVertex(conjugclass) then
      vertex := Vertex(sheet,data,rec(levelparam := conjugclass!.levelparam,
                                      classparam := conjugclass!.classparam,
                                      label := String(sheet!.largestlabel)));
    else
      vertex := Vertex(sheet,data,rec(levelparam := newlevel,
                                      label := String(sheet!.largestlabel)));
    fi;
  fi;
  
  if not HasseProperty(sheet) then
    return [vertex,true];
  fi;
  
  # now coming to the connections, we first search all higher levels
  # for vertices which contain our group. All those and those which are
  # even higher in the hierarchy meaning they contain vertices which contain
  # the new vertex, are stored in a list by their serial numbers to shorten
  # the search:
  
  Walkup := function(v)
    local   w;
    for w in v!.maximalin do
      if PositionSet(containerlist,w!.serial) <> fail then
        AddSet(containerlist,w!.serial);
        Walkup(w);
      fi;
    od;
  end;
  
  Walkdown := function(v)
    local   w;
    # first check if there are superfluos connections:
    for w in v!.maximalin do
      if PositionSet(containerlist,w!.serial) <> fail then
        # gotcha! Attention: new Edge not yet created, so no danger!
        Delete(sheet,w,v);
      fi;
    od;
    
    # now go down:
    for w in v!.maximals do
      if PositionSet(containedlist,w!.serial) <> fail then
        AddSet(containedlist,w!.serial);
        Walkdown(w);
      fi;
    od;
  end;
      
  containerlist := [];
  # all higher levels:
  lev := Position(Levels(sheet),newlevel)-1;
  while lev > 0 do
    # all classes:
    for cl in sheet!.levels[lev]!.classes do
      for v in cl do
        if PositionSet(containerlist,v!.serial) = fail then
          if IsSubgroup(v!.data.group,grp) then
            Edge(sheet,vertex,v);
            AddSet(containerlist,v!.serial);
            Walkup(v);
          fi;
        fi;
      od;
    od;
    lev := lev - 1;
  od;
  
  # we have now connected to all subgroups which contain our new one as
  # a maximal element and have stored the serial numbers of all vertices
  # that contain our new vertex.
  # we now do the same downwards but we cancel additionally all connections
  # between contained subgroups and overgroups.
  containedlist := [];
  # all lower levels:
  lev := Position(Levels(sheet),newlevel)+1;
  while lev <= Length(Levels(sheet)) do
    # all classes:
    for cl in sheet!.levels[lev]!.classes do
      for v in cl do
        if PositionSet(containedlist,v!.serial) = fail then
          if IsSubgroup(grp,v!.data.group) then
            AddSet(containedlist,v!.serial);
            Walkdown(v);
            Edge(sheet,vertex,v);
          fi;
        fi;
      od;
    od;
    lev := lev + 1;
  od;
  
  # now at last we are done.
  return [vertex,true];
  
end);

##
##  Another method for convenience:
##  Note that here the vertex is automatically selected!
##
InstallOtherMethod( InsertVertex,
    "for a graphic subgroup lattice, and a subgroup",
    true,
    [ IsGraphicSheet and IsGraphicPosetRep and IsGraphicSubgroupLattice,
      IsGroup ],
    0,
function(sheet,group)
  local l;
  l := InsertVertex(sheet,group,fail,[]);
  Select(sheet,l[1],true);
end);

    
#############################################################################
##
#M  NewInclusionInfo( <sheet>, <v1>, <v2> ) . . . . . . . . . . v1 lies in v2
##
##  For graphic group lattices without the HasseProperty we cannot calculate
##  all inclusion information for each new vertex. This operation is the
##  proposed method to enter an inclusion information which normally comes
##  out of the process of subgroup calculation into the poset. It should
##  normally only be called if one conjectures or knows that v1 is a
##  maximal subobject with respect to the current poset, but the methods
##  for this operation first check, if there is already a way from v1 up
##  to v2. If this is the case, nothing is done. Otherwise we have to check,
##  if this new connection can be established: If v2 lies in a lower level
##  than v1 (of course those two levels are not comparable, so by definition
##  both subgroups must lie in a level of their own!) then, we try
##  to move the level of v1 into a new level right below that of v2. If 
##  that does not work we try to move the level of v2 right over the level
##  of v1. If that does not work check if we know that v2 is contained in v1
##  In this case we call MergeVertices. Otherwise we finally give up and 
##  display an info!
##  Now we draw the connection but have to make sure, that this new connection
##  does not close a circle such that there is an edge in the poset which
##  connects a vertex "below" v1 to a vertex "over" v2. Therefore we 
##  calculate all vertices lying "below" v1 and "over" v2 and disconnect
##  them pairwise. This is all done by means of posets and not by means
##  of groups. There are no group inclusion checks performed!
InstallMethod( NewInclusionInfo,
    "for a graphic subgroup lattice, and two vertices",
    true,
    [ IsGraphicPosetRep and IsGraphicSubgroupLattice, IsGPVertex, IsGPVertex ],
    0,

function( sheet, v1, v2 )
  local   p1,  p2,  over,  Walkup,  under,  Walkdown,  v,  w;
  
  # first make sure that there is no "way" from v2 down to v1 on the 
  # connections which are already in the poset. We use the function
  # GPSearchWay in poset.gi. Documentation there says:
  #   The following function is only internal:
  #   Use it on your own risk and only if you know what you are doing!
  # So I (Max) say:
  #  *I know what I am doing!*
  if GPSearchWay(sheet, v2, v1, 
                 Position(sheet!.levelparams,v1!.levelparam)) then
    # note the order of the vertices in the calling convention!
    # see: I really know what I am doing!
    return;
  fi;
  # note: this works also, if v1 is in a higher level than v2 and is very
  #       fast in this case!
  
  # now check if the level of v1 is lower than that of v2:
  p1 := Position(sheet!.levelparams,v1!.levelparam);
  p2 := Position(sheet!.levelparams,v2!.levelparam);
  if p1 < p2 then
    # we have a problem, first we try to move p1 down:
    if MoveLevel(sheet,v1!.levelparam,p2) = fail then
      # that was no solution, we try to move p2 up:
      if MoveLevel(sheet,v2!.levelparam,p1) = fail then
        # that did not work either, so the last idea:
        if GPSearchWay(sheet,v1,v2,p2) then
          MergeVertices(sheet,v1,v2);
          return;   # we are done with this inclusion!
        else
          Info(GraphicLattice,1,"Cannot use inclusion ",v1!.label," in ",
               v2!.label," because of levels!");
          return;   # nothing to do!
        fi;
      else
        p2 := p1;
        p1 := p1 + 1;
      fi;
    else
      p1 := p2;
      p2 := p2 - 1;
    fi;   
    # if we reach this point, the levels are ok, p1 > p2
  elif p1 = p2 then   # equal levels, that is easy:
    # we can do this because we put vertices with infinite index in separate
    # levels each, so they must be equal if they are in some equal (finite)
    # index. FIXME
    MergeVertices(sheet,v1,v2);
    return;
  fi;
  
  # now we can begin our work. we don't have a way between the vertex v1 and
  # the vertex v2, which lies higher in the poset.
  # we collect now all vertices "over" v2 and all vertices "under" v1:
  over := [];
  Walkup := function(v)
    local   w;
    for w in v!.maximalin do
      if PositionSet(over,w) = fail then
        Walkup(w);
        AddSet(over,w);
      fi;
    od;
  end;
  
  Walkup(v2);
  
  under := [];
  Walkdown := function(v)
    local   w;
    for w in v!.maximals do
      if PositionSet(under,w) = fail then
        Walkdown(w);
        AddSet(under,w);
      fi;
    od;
  end;
  
  Walkdown(v1);
  
  # now we consider all pairs:
  for v in over do
    for w in under do
      if w in v!.maximals then
        Delete(sheet,v,w);   # we delete the edge
      fi;
    od;
  od;
  
  # a new edge:
  Edge(sheet,v1,v2);
  return;
end);


#############################################################################
##
#M  MergeVertices( <sheet>, <v1>, <v2> ) . . . . . . . . . . . merge vertices
##
##  For graphic group lattices without the HasseProperty we cannot calculate
##  all inclusion information for each new vertex. If we don't have
##  CanCompareSubgroups either, we have to think of the case where we have two
##  vertices to which belongs the same group respectively. If we come to
##  know this, then we have to fix this situation by merging vertices.
##  This operation does exactly this *without* further checks. The vertex
##  residing in a higher level or having a lower x-coordinate survives and
##  inherits all inclusion information the other has. The second one is
##  deleted.
InstallMethod( MergeVertices,
    "for a graphic subgroup lattice, and two vertices",
    true,
    [ IsGraphicPosetRep and IsGraphicSubgroupLattice, IsGPVertex, IsGPVertex],
    0,

function( sheet, v1, v2 )
  local   p1,  p2,  dummy,  v2maximalin,  v2maximals,  v,  lev,  cls;
  
  # we compare the levels:
  p1 := Position(sheet!.levelparams,v1!.levelparam);
  if p1 = fail then
    return fail;
  fi;
  p2 := Position(sheet!.levelparams,v2!.levelparam);
  if p2 = fail then
    return fail;
  fi;
  if p1 > p2 then
    dummy := v1;
    v1 := v2;
    v2 := dummy;
  fi;
  # now v1 is "higher", this is the one that survives
  
  # we remember the connections of v2:
  v2maximalin := ShallowCopy(v2!.maximalin);
  v2maximals := ShallowCopy(v2!.maximals);
  
  Delete(sheet,v2);  # now v2 is gone with all connections!
  
  # we use the inclusions of v2 as new inclusion information for v1:
  # note that it is possible that this can move around levels and even
  # call MergeVertices recursively! So we have to ensure that the vertices
  # in these lists (and v1) are still in the poset if we come to the new 
  # connections: 
  for v in v2maximalin do
    p1 := Position(sheet!.levelparams,v!.levelparam);
    if p1 <> fail then
      lev := sheet!.levels[p1];
      p2 := Position(lev!.classparams,v!.classparam);
      if p2 <> fail then
        cls := lev!.classes[p2];
        if Position(cls,v) <> fail then
          p1 := Position(sheet!.levelparams,v1!.levelparam);
          if p1 <> fail then
            lev := sheet!.levels[p1];
            p2 := Position(lev!.classparams,v1!.classparam);
            if p2 <> fail then
              cls := lev!.classes[p2];
              if Position(cls,v1) <> fail then
                # we have both!
                NewInclusionInfo(sheet,v1,v);
              fi;
            fi;
          fi;
        fi;
      fi;
    fi;
  od;
  for v in v2maximals do
    p1 := Position(sheet!.levelparams,v!.levelparam);
    if p1 <> fail then
      lev := sheet!.levels[p1];
      p2 := Position(lev!.classparams,v!.classparam);
      if p2 <> fail then
        cls := lev!.classes[p2];
        if Position(cls,v) <> fail then
          p1 := Position(sheet!.levelparams,v1!.levelparam);
          if p1 <> fail then
            lev := sheet!.levels[p1];
            p2 := Position(lev!.classparams,v1!.classparam);
            if p2 <> fail then
              cls := lev!.classes[p2];
              if Position(cls,v1) <> fail then
                # we have both!
                NewInclusionInfo(sheet,v,v1);
              fi;
            fi;
          fi;
        fi;
      fi;
    fi;
  od;
  return;
end);

  
#############################################################################
##
#M  CompareLevels(<poset>,<levelp1>,<levelp2>) . . . compares two levelparams
##
##  Compare two levelparams. -1 means that levelp1 is "higher", 1 means
##  that levelp2 is "higher", 0 means that they are equal. fail means that
##  they are not comparable. This method is for the case of subgroup lattices
##  parameters are integers or a list with first entry infinity. All those
##  "infinities" are not comparable. Negative values are Sizes instead of 
##  indices. They are lower than infinity and than all finite indices.
##  One has to make sure that the index is used if the whole group is finite,
##  because this method can not decide, if G is finite.
##
InstallMethod( CompareLevels,
    "for a graphic subgroup lattice, and two integers",
    true,
    [ IsGraphicPosetRep and IsGraphicSubgroupLattice, IsInt, IsInt ],
    0,

function( poset, l1, l2 )
  if IsList(l1) then          # infinity!
    if l2 > 0 then            # infinity lower than number
      return 1;
    elif IsList(l2)    then   # two infinities not comparable
      return fail;
    else                      # infinity higher than size
      return -1;
    fi;      
  elif l1 > 0 then
    if l2 > 0 then            # two indices, smaller index is higher
      if l1 < l2 then
        return -1;
      elif l1 > l2 then
        return 1;
      else
        return 0;             # they are equal
      fi;
    elif IsList(l2) then      # index higher than infinity
      return -1;
    else      # l2 < 0        # indices higher than sizes
      return -1;
    fi;
  else   # l1 < 0
    if l2 > 0 then            # indices higher than sizes
      return 1;
    elif IsList(l2) then      # infinite higher than sizes
      return 1;
    else                      # two indices, bigger size is higher
      if l1 < l2 then
        return 1;
      elif l1 = l2 then
        return 0;
      else    # l1 > l2
        return -1;
      fi;
    fi;
  fi;
end);


#############################################################################
##
##  Constructors:  
##
#############################################################################
  
#############################################################################
##
#F  GGLMakeSubgroupsMenu( <sheet>, <config> ) . . . . .  makes subgroups menu
##
##  This function is used to generate a menu out of the configuration data.
##
InstallGlobalFunction( GGLMakeSubgroupsMenu,
  function( sheet, config )
  
  local   entries,  types,  functions,  i,  c;
  
  entries := [];
  types := [];
  functions := [];
  
  for i in [1..Length(config)] do
    if IsBound(config) then
      c := config[i];
      entries[i] := c.name;
      functions[i] := GGLMenuOperation;
      if c.from = GGLfrom1 then
        if c.plural then
          types[i] := "forsubset";
        else
          types[i] := "forone";
        fi;
      elif c.from = GGLfrom2 then
        if c.plural then
          types[i] := "formin2";
        else
          types[i] := "fortwo";
        fi;
      elif c.from = GGLfromSet then
        types[i] := "forsubset";
      else
        types[i] := "forany";
      fi;
    fi;
  od;
  
  Menu( sheet, "Subgroups", entries, types, functions );
end);


#############################################################################
##
#M  GraphicSubgroupLattice(<G>) . . . . displays subgroup lattice graphically
#M  GraphicSubgroupLattice(<G>,<def>)  . . . . . . . . . . same with defaults
##
##  Displays a graphic poset which shows (parts of) the subgroup lattice of
##  the group <group>. Normally only the whole group and the trivial group are
##  shown (behaviour of "InteractiveLattice" in xgap3). Returns a
##  IsGraphicSubgroupLattice object. Calls DecideSubgroupLatticeType. See
##  there for details.
##
InstallMethod( GraphicSubgroupLattice,
    "for a group, and a record",
    true,
    [ IsGroup, IsRecord ],
    0,
        
function(G,def)
  local   latticetype,  defaults,  poset,  indices,  levelheight,  l,  str,  
          vmath,  v2,  v1;
  
  latticetype := DecideSubgroupLatticeType(G);
  # we do some heuristics to avoid the trivial group:
  # if we know all levels, we probably can calc. Size, if we shall generate
  # a vertex for the trivial subgroup, we should also know Size!
  if latticetype[1] or latticetype[4] then   
    # no trivial case:
    if Size(G) = 1 then
      return Error( "<G> must be non-trivial" );
    fi;
  fi;
  
  # we need a defaults record for the poset:
  defaults := rec(width := 800,
                  height := 600,
                  title := "GraphicSubgroupLattice");
  if HasName(G) then
    defaults.title := Concatenation(defaults.title," of ",Name(G));
  elif HasIdGroup(G) then
    defaults.title := Concatenation(defaults.title," of ",String(IdGroup(G)));
  fi;
  
  if IsBound(def.width) then defaults.width := def.width; fi;
  if IsBound(def.height) then defaults.height := def.height; fi;
  if IsBound(def.title) then defaults.title := def.title; fi;
  
  # we open a graphic poset:
  poset := GraphicPoset(defaults.title,defaults.width,defaults.height);
  # and make it a GraphicSubgroupLattice:
  SetFilterObj( poset, IsGraphicSubgroupLattice );
  
  poset!.group := G;
  
  # now the other filters, depending on type:
  if latticetype[1] then
    SetFilterObj(poset,KnowsAllLevels);
  fi;
  if latticetype[2] then
    SetFilterObj(poset,HasseProperty);
  fi;
  if latticetype[3] then
    SetFilterObj(poset,CanCompareSubgroups);
  fi;
  
  # initialize some components:
  poset!.selector := false;
  InstallCallback(poset,"Close",
          function(poset)
            if poset!.selector <> false then
              Close(poset!.selector);
              poset!.selector := false;
            fi;
          end);
          
  # set the limits:
  poset!.limits := rec(conjugates := 100);
  
  if KnowsAllLevels(poset) then
    # create all possible level parameters and levels:
    indices := DivisorsInt(Size(G));
    levelheight := QuoInt(poset!.height,Length(indices));
    for l in indices do
      str := "Index ";
      Append(str,String(l));
      CreateLevel(poset,l,str);
      ResizeLevel(poset,l,levelheight);
    od;
  else
    # we just create one or two levels:
    CreateLevel(poset,1,"Index 1");  # for the whole group
    if latticetype[4] then
      str := "Index ";
      Append(str,String(Size(G)));
      CreateLevel(poset,Size(G),str);
    fi;
  fi;
  
  # create one or two initial vertices (G itself and trivial subgroup):
  # we seperate the mathematical data and the graphical data:
  vmath := rec(group := G,
               isClassRep := true,
               info := rec(Index := 1));
  vmath.class := [vmath];
  vmath.classrep := vmath;
  v2 := Vertex(poset,vmath,rec(levelparam := vmath.info.Index, label := "G"));
  
  # we keep track of largest label:
  poset!.largestlabel := 1;
  # we keep track of largest number of infinity label
  poset!.largestinflevel := 0;
  
  if latticetype[4] then
    vmath := rec(group := TrivialSubgroup(G),
                 isClassRep := true,
                 info := rec(Index := Size(G)));
    vmath.class := [vmath];
    vmath.classrep := vmath;
    v1 := Vertex(poset,vmath,rec(levelparam := vmath.info.Index,label := "1"));
    
    # connect the two vertices
    Edge(poset,v1,v2);
  fi;
  
  # <G> is selected at first
  Select(poset,v2,true);
  
  # create menus:
  GGLMakeSubgroupsMenu(poset,latticetype[5]);
  poset!.menuoperations := latticetype[5];
  
  # Install the info method:
  poset!.infodisplays := latticetype[6];
  InstallPopup(poset,GGLRightClickPopup);
  
  # no vertex is green right now:
  poset!.lastresult := [];
  
  return poset;
end);

##
## without defaults record:
##
InstallOtherMethod(GraphicSubgroupLattice,
    "for a group",
    true,
    [ IsGroup ],
    0,
function(G)
  return GraphicSubgroupLattice(G,rec());
end);


#############################################################################
##
##  Decision function for subgroup lattice type:
##
#############################################################################


#############################################################################
##
#M  DecideSubgroupLatticeType(<grp>)  . . decides about the type of a lattice
##
##  This operation is called while creation of a new graphic subgroup lattice.
##  It has to decide about the type of the lattice. That means it has to
##  decide 5 questions:
##   1) Are all levels known right from the beginning?
##   2) Has the lattice the HasseProperty?
##   3) Can we test two subgroups for equality reasonably cheaply?
##   4) Shall we create a vertex for the trivial subgroup at the beginning?
##   5) What menu operations are possible?
##   6) What information is displayed on RightClick?
##  Returns a list. The first four entries are boolean values for  questions
##  1-4. Note that if the answer to 2 is true, then the answer to 3 must also
##  be true. The fifth and sixth entry are configuration lists as explained 
##  in the configuration section of "ilatgrp.gi" for menu operations and
##  info displays respectively.
##
##  The following is the default "fallback" method suitable for reasonably
##  small finite groups.
##
InstallMethod( DecideSubgroupLatticeType,
    "for a group",
    true,
    [ IsGroup ],
    0,
        
function( G )
  local   knowslevels;
  if Size(G) > 10^17 then    # that is just heuristic!
    knowslevels := false;
  else
    knowslevels := Length(DivisorsInt(Size(G))) < 50;
  fi;
  return [knowslevels,
          true,         # we assume HasseProperty
          true,         # we assume we can compare groups
          true,         # we want the trivial subgroup
          GGLMenuOpsForFiniteGroups,
          GGLInfoDisplaysForFiniteGroups];
end);

## for finitely presented groups:
InstallMethod( DecideSubgroupLatticeType,
    "for a group",
    true,
    [ IsGroup and IsFpGroup ],
    0,
        
function( G )
  return [false,        # we create levels dynamically
          false,        # we do not assume HasseProperty
          false,        # we assume we cannot compare groups efficiently
          false,        # we don't want the trivial subgroup
          GGLMenuOpsForFpGroups,
          GGLInfoDisplaysForFpGroups];
end);


############################################################################
##
##  Operations to switch between graphics and GAP calculations:
##
############################################################################


############################################################################
##
#M  SelectedGroups( <sheet> ) . . . . . . .  returns list of selected groups
##
##  Uses the `Selected' operation to get a list of vertices and returns the
##  corresponding list of subgroups.
##
InstallMethod( SelectedGroups,
    "for a graphic subgroup lattice",
    true,
    [ IsGraphicSheet and IsGraphicPosetRep and IsGraphicSubgroupLattice ],
    0,
function( sheet )
  return List(Selected(sheet),v->v!.data.group);
end);


############################################################################
##
#M  SelectGroups( <sheet>, <list> ) . . . . . . . . select subgroups in list
##
##  Uses the `Select' operation to select exactly those vertices to which
##  the subgroups in the supplied list belong. Be careful: We use
##  `IsIdenticalObj' here because comparison must be fast. If a subgroup is
##  not yet as vertex in the lattice, only a warning is printed. If two
##  or more vertices have the subgroup as associated group, only one of them
##  is selected.
##
InstallMethod( SelectGroups,
    "for a graphic subgroup lattice",
    true,
    [ IsGraphicSheet and IsGraphicPosetRep and IsGraphicSubgroupLattice,
      IsList ],
    0,
function( sheet, li )
  local   g,  v;
  DeselectAll(sheet);
  for g in li do
    if not IsGroup(g) then
      Info(GraphicLattice,1,"Warning: This is no subgroup: ",g);
    else
      v := WhichVertex(sheet,g,function(a,b) 
                                 return a = b.group;
                               end );
      if v = fail then
        Info(GraphicLattice,1,"Warning: Subgroup not in lattice: ",g);
      else
        Select(sheet,v,true);
      fi;
    fi;
  od;
end);


#############################################################################
##  
##  Some small things that don't fit in another section:
##
#############################################################################

##
##  ViewObj methods:
##
InstallMethod( ViewObj,"for a graphic subgroup lattice",true,
        [IsGraphicSheet and IsGraphicSheetRep and IsGraphicGraphRep and 
         IsGraphicPosetRep and IsGraphicSubgroupLattice],
        0,function( sheet ) 
  Print("<");
  if not IsAlive(sheet) then
    Print("dead ");
  fi;
  Print("graphic subgroup lattice \"",sheet!.name,"\">");
end);
  
