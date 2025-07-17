REPORT zt9r_method_call_hierarchy.
TABLES seocompo.

TYPES: BEGIN OF ty_ref,
         method TYPE seocmpname,
         enclob TYPE seoclsname,
         refmet TYPE seocmpname,
         refenc TYPE seoclsname,
       END OF ty_ref.


DATA gt_ref TYPE STANDARD TABLE OF ty_ref.

DATA gv_pos  TYPE i.
DATA gv_call TYPE i.


PARAMETERS     p_clsnam TYPE seoclsname DEFAULT 'CL_SALV_TABLE'.
SELECT-OPTIONS s_cmpnam FOR seocompo-cmpname.
PARAMETERS p_enclo AS CHECKBOX DEFAULT 'X'.

START-OF-SELECTION.
  PERFORM find.
  PERFORM ref USING space.


  LOOP AT gt_ref ASSIGNING FIELD-SYMBOL(<ref>).
    DATA(ref) = |{ <ref>-refenc }=>{ <ref>-refmet }|.
    DATA(met) = |{ <ref>-enclob }=>{ <ref>-method }|.
    WRITE: / ref, AT 50 met.
  ENDLOOP.

*&---------------------------------------------------------------------*
*&      Form  find
*&---------------------------------------------------------------------*
FORM find.

  DATA lt_seocompo TYPE STANDARD TABLE OF seocompo.
  FIELD-SYMBOLS <compo> TYPE seocompo.

  SELECT * FROM seocompo INTO TABLE lt_seocompo
   WHERE clsname = p_clsnam
     AND cmpname IN s_cmpnam
     AND cmptype = 1.
  LOOP AT lt_seocompo ASSIGNING <compo>.
    PERFORM find_component USING <compo>-cmpname <compo>-clsname.
  ENDLOOP.

ENDFORM.                    "find

*&---------------------------------------------------------------------*
*&      Form  find_component
*&---------------------------------------------------------------------*
FORM find_component USING component enclosed_object.

  FIELD-SYMBOLS <ref> TYPE ty_ref.

  DATA ls_findstring    TYPE rsfind.
  DATA lt_findstrings   TYPE STANDARD TABLE OF rsfind.

  DATA ls_foundstring   TYPE rsfind.
  DATA lt_foundstrings  TYPE STANDARD TABLE OF rsfind.

  DATA ls_scope_object  TYPE rsfind.
  DATA lt_scope_objects TYPE STANDARD TABLE OF rsfind.

  DATA lt_founds        TYPE STANDARD TABLE OF rsfindlst.
  FIELD-SYMBOLS <found> TYPE rsfindlst.

  CLEAR lt_findstrings.
  CLEAR lt_foundstrings.
  ls_findstring-object   = component.
  ls_findstring-encl_obj = enclosed_object.
  APPEND ls_findstring TO lt_findstrings.

  APPEND INITIAL LINE TO gt_ref ASSIGNING <ref>.
  <ref>-method = component.
  <ref>-enclob = enclosed_object.

*  ls_scope_object-object = enclosed_object.
*  APPEND ls_scope_object TO lt_scope_objects. "Dauert zu lange...

  CALL FUNCTION 'RS_EU_CROSSREF'
    EXPORTING
      i_find_obj_cls               = 'OM'
      i_scope_obj_cls              = ' '
      rekursiv                     = ' '
      i_answer                     = 'N'
      no_dialog                    = 'X'
      expand_source_in_batch_mode  = 'X'
      expand_source_in_online_mode = ' '
      without_text                 = ' '
      with_generated_objects       = ' '
    TABLES
      i_findstrings                = lt_findstrings
      o_founds                     = lt_founds
      o_findstrings                = lt_foundstrings
      i_scope_objects              = lt_scope_objects
    EXCEPTIONS
      not_executed                 = 1
      not_found                    = 2
      illegal_object               = 3
      no_cross_for_this_object     = 4
      batch                        = 5
      batchjob_error               = 6
      wrong_type                   = 7
      object_not_exist             = 8
      OTHERS                       = 9.
  IF sy-subrc = 0.
    LOOP AT lt_founds ASSIGNING <found> WHERE object_cls = 'OM'.
      IF p_enclo <> space.
        CHECK <found>-encl_objec = enclosed_object.
      ENDIF.
      CHECK <found>-program NA '='.
      <ref>-refmet = <found>-program.
      <ref>-refenc = <found>-encl_objec.
    ENDLOOP.
  ENDIF.

ENDFORM.                    "find_component

*&---------------------------------------------------------------------*
*&      Form  ref
*&---------------------------------------------------------------------*
FORM ref USING met.

  FIELD-SYMBOLS <ref> TYPE ty_ref.

  ADD 1 TO gv_call.
  CHECK gv_call < 100.

  ADD 2 TO gv_pos.

  WRITE: AT /gv_pos met.

  LOOP AT gt_ref ASSIGNING <ref> WHERE refmet = met.
    IF met IS INITIAL.
      FORMAT COLOR COL_TOTAL.
    ELSE.
      FORMAT COLOR OFF.
    ENDIF.

    PERFORM ref USING <ref>-method.
  ENDLOOP.
  SUBTRACT 2 FROM gv_pos.

ENDFORM.                    "ref
