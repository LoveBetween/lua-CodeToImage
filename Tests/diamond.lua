                                                                         op=
                                                                        {["add"
                                                                      ]="+",["sub"
                                                                     ]="-",["mul"
                                                                    ]="*",["div"
                                                                   ]="/",["idiv"]=
                                                                  "//",["mod"]="%",
                                                                ["pow"]="^",["concat"
                                                               ]="..",["band"]="&",["bor"
                                                              ]="|",["bxor"]="~",["shl"
                                                             ]="<<",["shr"]=">>",["eq"]=
                                                            "==",["ne"]="~=",["lt"]="<",[
                                                          "gt"]=">",["le"]="<=",["ge"]=">="
                                                         ,["and"]="and",["or"]="or",["unm"]
                                                        ="-",["len"]="#",["bnot"]="~",["not"
                                                       ]="not"} local ns={["space"]=2} local ps
                                                      ={["space"]=1} local pp={} local function
                                                     pretty(t) if type(t) ~= "table" then return
                                                    tostring(t) end local parts={} for i=1,# t do
                                                   parts[# parts + 1]=pretty(t[i]) end return table
                                                 ["concat"](parts,"") end local block2str,stm2str,exp2tab
                                                ,var2tab local explist2str,varlist2tab,parlist2tab,fieldlist2tab
                                               flat= function(...) local t={} for _,arg in pairs({...}
                                              ) do if type(arg) == "table" and not arg["space"] then for
                                             _,e in pairs(arg) do t[# t + 1]=e end else t[# t + 1]=arg end
                                            end return t end local function iscntrl(x) if (x >= 0 and x <=
                                           31) or (x == 127) then return true end return false end local function
                                         isprint(x) return not iscntrl(x) end local function fixed_string(str
                                       ) local new_str="" for i=1,string["len"](str) do char=string["byte"](str
                                      ,i) if char == 34 then new_str=new_str .. string["format"]("\\\"") elseif
                                      char == 92 then new_str=new_str .. string["format"]("\\\\") elseif char ==
                                     7 then new_str=new_str .. string["format"]("\\a") elseif char == 8 then new_str
                                  =new_str .. string["format"]("\\b") elseif char == 12 then new_str=new_str .. string
                                 ["format"]("\\f") elseif char == 10 then new_str=new_str .. string["format"]("\\n"
                                ) elseif char == 13 then new_str=new_str .. string["format"]("\\r") elseif char == 9
                                then new_str=new_str .. string["format"]("\\t") elseif char == 11 then new_str=new_str
                               .. string["format"]("\\v") else if isprint(char) then new_str=new_str .. string["format"
                            ]("%c",char) else new_str=new_str .. string["format"]("\\%03d",char) end end end return new_str
                            end local function name2tab(name) return string["format"]("%s",name) end local function string2str
                          (s) return string["format"]("\"%s\"",fixed_string(s) ) end var2tab= function(var) local tag=var[
                         "tag"] local t={} if tag == "Id" then t=name2tab(var[1]) elseif tag == "Index" then t={exp2tab(var[
                        1]) ,"[",exp2tab(var[2]) ,"]"} else error("expecting a variable, but got a :" .. tag) end return t end
                       varlist2tab= function(varlist) local l={} for k,v in ipairs(varlist) do l[# l + 1]=var2tab(v) l[# l + 1
                     ]="," end l[# l]=nil return l end parlist2tab= function(parlist) local l={} local len=# parlist local is_vararg
                    =false if len > 0 and parlist[len]["tag"] == "Dots" then is_vararg=true len=len - 1 end local i=1 while i <=
                    len do l[# l + 1]=var2tab(parlist[i]) l[# l + 1]="," i=i + 1 end if is_vararg then l[# l + 1]="..." else table["remove"]
                  (l, # l) end return l end fieldlist2tab= function(fieldlist) local l={} for k,v in ipairs(fieldlist) do local tag
                =v["tag"] if tag == "Pair" then if v[1]["tag"] == "String" then l[# l + 1]=flat("[",exp2tab(v[1]) ,"]","=",exp2tab(v
               [2]) ) else l[# l + 1]=flat(exp2tab(v[1]) ,"=",exp2tab(v[2]) ) end else l[# l + 1]=flat(exp2tab(v) ) end l[# l + 1]=","
               end if # l > 0 then l[# l]=nil return l else return "" end end exp2tab= function(exp) local tag=exp["tag"] local t={} if
              tag == "Nil" then t={"nil"} elseif tag == "Dots" then t={"..."} elseif tag == "Boolean" then t={tostring(exp[1]) } elseif 
            tag == "Number" then t={tostring(exp[1]) } elseif tag == "String" then t={string2str(exp[1]) } elseif tag == "Function" then 
          t={ns,"function(",parlist2tab(exp[1]) ,")",ns,block2str(exp[2]) ,ns,"end",ns} elseif tag == "Table" then t={"{",fieldlist2tab(exp
         ) ,"}",ns} elseif tag == "Op" then t={op[exp[1]],ns,exp2tab(exp[2]) } if exp[3] then t={exp2tab(exp[2]) ,ns,op[exp[1]],ns,exp2tab(
        exp[3]) } end elseif tag == "Paren" then t={"(",exp2tab(exp[1]) ,")",ns} elseif tag == "Call" then t={exp2tab(exp[1]) ,"("} if exp[2
       ] then for i=2,# exp do t=flat(t,exp2tab(exp[i]) ,",") end t[# t]=nil end t=flat(t,")",ns) elseif tag == "Invoke" then t={exp2tab(exp[1
      ]) ,":",name2tab(exp[2][1]) ,"("} if exp[3] then for i=3,# exp do t=flat(t,exp2tab(exp[i]) ,",") end t[# t]=nil end t=flat(t,")",ns) elseif
     tag == "Id" or tag == "Index" then t={var2tab(exp) } else error("expecting an expression, but got a " .. tag) end return t end explist2str=
    function(explist) local l={} for k,v in ipairs(explist) do l[k]=exp2tab(v) end if # l > 0 then return l else return "" end end stm2str= function(
  stm) local tag=stm["tag"] local t={} if tag == "Do" then for k,v in ipairs(stm) do t[k]=stm2str(v) end return t elseif tag == "Set" then t={varlist2tab
 (stm[1]) ,"=",explist2str(stm[2]) ,ns} elseif tag == "While" then t={ns,"while",ns,exp2tab(stm[1]) ," do ",block2str(stm[2]) ,ns,"end",ns} elseif tag
 == "Repeat" then t={ns,"repeat",ns,block2str(stm[1]) ,ns,"until",ns,exp2tab(stm[2]) } elseif tag == "If" then for i=1,# stm - 1,2 do if i == 1 then 
 t={t,ns,"if",ns,exp2tab(stm[i]) ,ns,"then",ns,block2str(stm[i + 1]) } else t={t,ns,"elseif",ns,exp2tab(stm[i]) ,ns,"then",ns,block2str(stm[i + 1]) 
  } end end if # stm % 2 == 1 then t={t,ns,"else",ns,block2str(stm[# stm]) } end t=flat(t,ns,"end",ns) elseif tag == "Fornum" then t={ns,"for",ns,
   var2tab(stm[1]) ,"=",exp2tab(stm[2]) ,",",exp2tab(stm[3]) } if stm[5] then t={t,",",exp2tab(stm[4]) ,ns,"do",ns,block2str(stm[5]) ,ns,"end",ns
    } else t={t,ns,"do",ns,block2str(stm[4]) ,ns,"end",ns} end elseif tag == "Forin" then t={ns,"for",ns,varlist2tab(stm[1]) ,ns,"in",ns,explist2str
      (stm[2]) ,ns,"do",ns,block2str(stm[3]) ,ns,"end",ns} elseif tag == "Local" then t={ns,"local",ns,varlist2tab(stm[1]) } if # stm[2] > 0 then
        t={t,"=",explist2str(stm[2]) } end t=flat(t,ns) elseif tag == "Localrec" then t={"local",ns,"function",ns,var2tab(stm[1][1]) ,"(",parlist2tab
        (stm[2][1][1]) ,")",ns,block2str(stm[2][1][2]) ,ns,"end",ns} elseif tag == "Goto" or tag == "Label" then t={"::",name2tab(stm[1]) ,"::"
         } elseif tag == "Return" then t={"return",ns,explist2str(stm) } elseif tag == "Break" then elseif tag == "Call" then local fn=pretty
          (exp2tab(stm[1]) ) if string["sub"](fn,1,1) == "\"" then fn=string["sub"](fn,2,- 2) end t={fn,"("} if stm[2] then for i=2,# stm 
            do if i < # stm then t={t,exp2tab(stm[i]) ,",",ns} else t={t,exp2tab(stm[i]) } end end end t=flat(t,")",ns) elseif tag == "Invoke"
              then t={exp2tab(stm[1]) ,":",name2tab(stm[2][1]) ,"("} if stm[3] then for i=3,# stm do t={t,",",exp2tab(stm[i]) } end end 
              t=flat(t,")",ns) else error("expecting a statement, but got a " .. tag) end return t end block2str= function(block) local
                l={} for k,v in ipairs(block) do l[k]=stm2str(v) end return {l} end merge_spaces= function(o) assert(type(o) == "table"
                , "wrong type, table expected") local space=0 local i=1 while i <= # o do  local item=o[i] if type(item) == "table" 
                  and type(item["space"]) == "number" then if space > 0 then item["space"]=math["max"](item["space"],space) table["remove"]
                   (o, i - 1) i=i - 1 end space=item["space"] else space=0 end i=i + 1 end return o end local function flatten_output
                    (t) if type(t) ~= "table" then return {tostring(t) } end if t["space"] and t["space"] > 0 then return {t} end
                      local parts={} for _,v in ipairs(t) do local flattened=flatten_output(v) for _,item in ipairs(flattened) 
                      do parts[# parts + 1]=item end end return parts end dump= function(o,space_nb) if type(o) == "table" then
                         local s="" for k,v in pairs(o) do if type(v) == "table" then if v["space"] > 1 then s=s .. " " else 
                         s=s .. string["rep"](" ",space_nb) end else s=s .. v end end return s else return tostring(o) end end
                           local function circle_fn(height,ratio,radius) local width=math["floor"](math["sqrt"](radius ^ 2
                            - (radius - height) ^ 2) ) * 2 local start=math["floor"](((radius * 2 - width) / 2) * ratio) 
                            width=math["floor"](width * ratio) return {width,start} end local function rectangle_fn(height
                              ,ratio,width) return {width,0} end local function sin_fn(height,ratio,max_width,period) local
                                width=math["abs"](math["sin"](height / period) * max_width) local start=math["floor"](
                                (max_width - width) / 2 * ratio) width=math["floor"](width * ratio) return {width,start
                                 } end local function diamond_fn(height,ratio,max_width) local te=(math["floor"](height
                                   / max_width) % 2) local width=(1 - te) * (height % max_width) + te * (max_width
                                     - (height % max_width) ) local start=math["floor"]((max_width - width) / 2 *
                                      ratio) width=width * ratio return {width,start} end local function random_worm_fn
                                      (height,ratio,width,first_start,bits,seed) local start=first_start for i
                                       =0,height do local divi=((i * bits) % 64) start=start + (2 ^ (bits - 1
                                        ) - (math["floor"]((seed * divi) ) % (2 ^ bits) + 0.5) ) print((math
                                          ["floor"]((seed * divi) ) % (2 ^ bits) ) ) end return {width,start
                                           } end dump_shape= function(o,space_nb,ratio,shape_fn,...) local
                                             height=1 local shape=shape_fn(height,ratio,...) local width
                                             =shape[1] local start=shape[2] if type(o) == "table" then 
                                              local s=string["rep"](" ",start) for _,v in ipairs(o) do
                                                 if type(v) == "table" and type(v["space"]) == "number"
                                                  then if v["space"] > 1 then s=s .. " " width=width
                                                   - 1 else s=s .. string["rep"](" ",space_nb) width
                                                   =width - space_nb end else s=s .. v width=width
                                                     - string["len"](v) end if width <= 0 then s
                                                      =s .. "\n" height=height + 1 local shape=
                                                       shape_fn(height,ratio,...) width=shape[
                                                        1] start=shape[2] s=s .. string["rep"
                                                         ](" ",start) end end return s else
                                                           return tostring(o) end end pp["tostring"
                                                            ]= function(t) assert(type(t)
                                                              == "table") return dump_shape
                                                              (merge_spaces(flatten_output
                                                               (block2str(t) ) ) ,0,2.4
                                                                ,diamond_fn,62,10) end
                                                                   pp["print"]= function(
                                                                   t) assert(type(
                                                                    t) == "table"
                                                                     ) print(pp
                                                                      ["tostring"
                                                                        ](t) 
                                                                         ) end
                                                                           
                                                                         return
                                                                         pp