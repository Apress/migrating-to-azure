--------------------------------------------------------------------------------
-- ARTS_DWM_3_2014-01-16.sql - Generate DDL from ERWIN for SQL Server 2012    --
-------------------------------------------------------------------------------- 

CREATE TYPE t_ISO_6709LongitudeLatitude
	FROM VARCHAR(30) NULL
go



CREATE TYPE QuantityInteger
	FROM INTEGER NULL
go



CREATE TYPE ISO_4217_CurrencyCode_char_3_
	FROM CHAR(3) NULL
go



CREATE TYPE UniversalTime
	FROM CHAR(7) NULL
go



--------------------------------------------------------------------------------
-- Function FN_SPLIT - Takes in a field containing concatenated key values of --
-- flattened hierarchies, breaks it apart into a table of separate strings    --
-- that can be reassembled or otherwise used as separate variables.           --
--------------------------------------------------------------------------------
--drop function SPLIT;
CREATE FUNCTION [dbo].[FN_SPLIT] 
   (  @DELIMITER VARCHAR(5), 
      @LIST      VARCHAR(MAX) 
   ) 
   RETURNS @TABLEOFVALUES TABLE 
      (  ROWID   SMALLINT IDENTITY(1,1), 
         [VALUE] VARCHAR(MAX) 
      ) 
AS 
   BEGIN
    
      DECLARE @LENSTRING INT 
 
      WHILE LEN( @LIST ) > 0 
         BEGIN 
         
            SELECT @LENSTRING = 
               (CASE CHARINDEX( @DELIMITER, @LIST ) 
                   WHEN 0 THEN LEN( @LIST ) 
                   ELSE ( CHARINDEX( @DELIMITER, @LIST ) -1 )
                END
               ) 
                                
            INSERT INTO @TABLEOFVALUES 
               SELECT SUBSTRING( @LIST, 1, @LENSTRING )
                
            SELECT @LIST = 
               (CASE ( LEN( @LIST ) - @LENSTRING ) 
                   WHEN 0 THEN '' 
                   ELSE RIGHT( @LIST, LEN( @LIST ) - @LENSTRING - 1 ) 
                END
               ) 
         END
          
      RETURN 
      
   END
--------------------------------------------------------------------------------
-- End of Function	                                                          --
--------------------------------------------------------------------------------

go



-------------------------------------------------------------------------------
-- FN_REVSPLIT - Reverse delimited string order for bottom up flattened      --
---------------- hierarchy keys to a left to right TOP DOWN string so the    --
-- hierarchy levels are correctly represented for top down listing           --
-------------------------------------------------------------------------------
--drop FUNCTION FN_REVSPLIT
CREATE FUNCTION [dbo].[FN_REVSPLIT]
    (
        @Input nvarchar(4000)
       ,@Delimiter nvarchar(5)
    )

    RETURNS nvarchar(4000)
    AS

BEGIN

    DECLARE @Output nvarchar(4000)

WHILE LEN(@Input)> 0
    BEGIN
        IF CHARINDEX(@Delimiter, @Input) > 0
            BEGIN
                SET @Output = SUBSTRING(@Input,0,CHARINDEX(@Delimiter, @Input)) + @Delimiter + ISNULL(@Output,'')
                SET @Input = SUBSTRING(@Input,CHARINDEX(@Delimiter, @Input)+1,LEN(@Input))
            END
        ELSE
            BEGIN
                SET @Output = @Input + @Delimiter + ISNULL(@Output,'')
                SET @Input = ''
            END
   END
   RETURN SUBSTRING(@Output,0,LEN(@Output))

END

--------------------------------------------------------------------------------
-- Function Test                                                              --
--------------------------------------------------------------------------------

go



-- drop function    dbo.FN_RP_CP_EXTR;
--------------------------------------------------------------------------------
-- Function: FN_RP_CP_EXTR - Extract Calendar Period Lable and Name from      --
--           concatenated calendar period hierarchy column                    --
--                                                                            --
--           This is version 1 of this function.  It will be replaced in      --
--           future ARTS DWM releases.  It is limited to yeras, seasons,      --
--           quarters and periods (months) for the NRF 4-5-4 calendar         --
--------------------------------------------------------------------------------
-- Input Param: Level Path - calendar level labels (e.g. YEAR, QUARTER, etc.) --
--              Level Name - calendar level names (e.g. 2013, 1, etc.)        --
--              Delimiter - character used to separate values we use a '|'    --
--              Return Calendar Level - Tells Function what set of calendar   --
--                                      hierarchy labels and values to return --
--                                                                            --
--    Value of Return Calendar Level (@return_ca_lvl):                        --
--   'PERIOD'  returns <calendar year label>:<calendar year name> + ' ' +     --
--                     <calendar period label>:<calendar period name>         --
--                                                                            --
--   'SEASON'  returns <calendar year label>:<calendar year name> + ' ' +     --
--                     <calendar season label>:<calender season name>         --
--                                                                            --
--   'QUARTER' returns <calendar year label>:<calendar year name> + ' ' +     --
--                     <calendar quarter label>:<calendar quarter name>       --
--   'YEAR' returns <calendar year label>:<calendar year name>                --
--------------------------------------------------------------------------------
create function  dbo.FN_RP_CP_EXTR
    (
       @lvl_pth as varchar(4000)
      ,@lvl_nm as varchar(4000)
      ,@delimiter as char(1)
      ,@return_ca_lvl as varchar(20)
    )
    returns varchar(4000) as

BEGIN
    ----------------------------------------------------------------------------
    -- Return string area where all of the pieces are assembled and returned  --
    -- from this function                                                     --
    ----------------------------------------------------------------------------
    Declare @StrWorkArea as varchar(4000)=''

    ----------------------------------------------------------------------------
    -- Calendar level name variables                                          --
    ----------------------------------------------------------------------------
    Declare @StrYearNm as char(4)=''
    Declare @StrSeasonNm as varchar(255)=''
    Declare @StrQtrNm as varchar(255)=''
    Declare @StrPrdNm as varchar(255)=''
    ----------------------------------------------------------------------------
    -- Calendar level label variables                                         --
    ----------------------------------------------------------------------------
    Declare @strYearLvl as varchar(255)=''
    Declare @strSeasonLvl as varchar(255)=''
    Declare @strQtrLvl as varchar(255)=''
    Declare @strPrdLvl as varchar(255)=''
    ----------------------------------------------------------------------------
    -- Pointer variables used in charindex and substring functions            --
    ----------------------------------------------------------------------------
    Declare @start as integer=0
    Declare @nextdelimit as integer=0
    ----------------------------------------------------------------------------
    -- Length variables for input calendar hierarchy labels and name strings  --
    -- used to test for end of decomposition of character strings             --
    ----------------------------------------------------------------------------    
    Declare @lvl_nm_lth as integer=0
    Declare @lvl_pth_lth as integer=0
    ----------------------------------------------------------------------------
    -- Set string lengths for calendar level names and labels                 --
    ----------------------------------------------------------------------------
    set @lvl_nm_lth = len(@lvl_nm)
    set @lvl_pth_lth = len(@lvl_pth)

    set @start = 0
    BEGIN
       -------------------------------------------------------------------------
       -- Separate out the NAME parts of the calendar period                  --
       -------------------------------------------------------------------------
       -- Year                                                                --
       -------------------------------------------------------------------------
       set @nextdelimit = charindex(@delimiter,@lvl_nm,@start)
       If @nextdelimit = 0 goto EndOfTextString
       set @StrYearNm = substring(@lvl_nm,@start,@nextdelimit)
       -------------------------------------------------------------------------
       -- Season                                                              --
       -------------------------------------------------------------------------
       set @start = @nextdelimit + 1
       set @nextdelimit = charindex(@delimiter,@lvl_nm,@start)
       If @nextdelimit = 0 
           BEGIN
               set @StrSeasonNm = substring(@lvl_nm,@start,@lvl_nm_lth - @start + 1)
               goto EndOfTextString
           END
       set @StrSeasonNm = substring(@lvl_nm,@start,@nextdelimit - @start)
       -------------------------------------------------------------------------
       -- Quarter                                                             --
       -------------------------------------------------------------------------
       set @start = @nextdelimit + 1
       set @nextdelimit = charindex(@delimiter,@lvl_nm,@start)
       If @nextdelimit = 0 
           BEGIN
               set @StrQtrNm = substring(@lvl_nm,@start,@lvl_nm_lth - @start + 1)
               goto EndOfTextString
           END
       set @StrQtrNm = substring(@lvl_nm,@start,@nextdelimit - @start)
       -------------------------------------------------------------------------
       -- Period                                                              --
       -------------------------------------------------------------------------
       set @start = @nextdelimit + 1
       set @nextdelimit = charindex(@delimiter,@lvl_nm,@start)
       If @nextdelimit = 0 
           BEGIN
               set @strPrdNm = substring(@lvl_nm,@start,@lvl_nm_lth - @start + 1)
               goto LookAtLevel   -- Here's the problem
           END
       set @strPrdNm = substring(@lvl_nm,@start,@nextdelimit - @start)

       -------------------------------------------------------------------------
       -- Separate out LEVEL label                                            --
       -------------------------------------------------------------------------

       LookAtLevel:
       -------------------------------------------------------------------------
       -- Year Level Label                                                    --
       -------------------------------------------------------------------------
       set @start = 1
       set @nextdelimit = charindex(@delimiter,@lvl_pth,@start)
       If @nextdelimit = 0 goto EndOfTextString
       set @strYearLvl = substring(@lvl_pth,@start,@nextdelimit - 1) -- You may want to subtract 1 test and see

       -------------------------------------------------------------------------
       -- Season Level Label                                                  --
       -------------------------------------------------------------------------
       set @start = @nextdelimit + 1
       set @nextdelimit = charindex(@delimiter,@lvl_pth,@start)
       if @nextdelimit = 0
           BEGIN
               set @strSeasonLvl = substring(@lvl_pth,@start,@lvl_pth_lth - @start + 1)
               goto EndOfTextString
           END
       set @strSeasonLvl = substring(@lvl_pth,@start,@nextdelimit - @start)

       -------------------------------------------------------------------------
       -- Quarter Level Label                                                 --
       -------------------------------------------------------------------------
       set @start = @nextdelimit + 1
       set @nextdelimit = charindex(@delimiter,@lvl_pth,@start)
       if @nextdelimit = 0
           BEGIN
               set @strQtrLvl = substring(@lvl_pth,@start,@lvl_pth_lth - @start + 1)
               goto EndOfTextString
           END
       set @strQtrLvl = substring(@lvl_pth,@start,@nextdelimit - @start)

       -------------------------------------------------------------------------
       -- Period (month) Level Label                                          --
       -------------------------------------------------------------------------
       set @start = @nextdelimit + 1
       set @nextdelimit = charindex(@delimiter,@lvl_pth,@start)
       if @nextdelimit = 0
           BEGIN
               set @strPrdLvl = substring(@lvl_pth,@start,@lvl_pth_lth - @start + 1)
               goto EndOfTextString
           END
       set @strPrdLvl = substring(@lvl_pth,@start,@nextdelimit - @start)

       EndOfTextString:   -- You've run out of delimiters so stop

    END
    ----------------------------------------------------------------------------
    -- At this point we've decomposed the calendar level into separate level  --
    -- name and level label components.  Now we will evaluate the             --
    -- @return_ca_lvl input parameter which tells us what parts to reassemble --
    -- and return.  In this sample, we're returning calendar year and the     --
    -- relative NRF period in that year.                                      --
    --                                                                        --
    -- We will generalize this query in future releases.                      --
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- TEST CODE to reassemble all parts of the calendar level down to period --
    ----------------------------------------------------------------------------
    --set @StrWorkArea = @StrYearLvl + ': ' + 
    --  @StrYearNm + ' ' + @StrSeasonLvl + ': ' + 
    --	@StrSeasonNm + ' ' +@StrQtrLvl + ': ' +  
    --	@StrQtrNm  + ' ' +
    --  @strPrdLvl + ': ' + @strPrdNm 	

    ----------------------------------------------------------------------------
    -- Build the @StrWorkArea based on the options selected by the calling    --
    -- logic.  Note we return YEAR plus the requested period                  --
    ----------------------------------------------------------------------------
    set @StrWorkArea =
        case 
            when @return_ca_lvl = 'PERIOD' then
                @strYearLvl + ':' + @strYearNm + ' ' +
                @strPrdLvl + ':' + @strPrdNm

            when @return_ca_lvl = 'QUARTER' then
                @strYearLvl + ':' + @strYearNm + ' ' +
                @StrQtrLvl + ':' + @strQtrNm
            
            when @return_ca_lvl = 'SEASON' then
                @strYearLvl + ':' + @strYearNm + ' ' +
                @strSeasonLvl + ':' + @strSeasonNm

            when @return_ca_lvl = 'YEAR' then 
                @strYearLvl + ':' + @strYearNm

            else 'Invalid calendar level requested'
    end 
    return @StrWorkArea
END
;
--------------------------------------------------------------------------------
-- End Function: FN_RP_CP_EXTR                                                --
--------------------------------------------------------------------------------

go
--------------------------------------------------------------------------------
-- Create ARTS DWM 3 Base Tables                                              --
--------------------------------------------------------------------------------

CREATE TABLE CA_PRD_RP
( 
	ID_PRD_RP            integer  NOT NULL ,
	ID_CLD               integer  NOT NULL ,
	ID_CLD_LV            integer  NOT NULL ,
	ID_CLD_PRD_SRT       integer  NOT NULL ,
	ID_CLD_PRD_END       integer  NOT NULL ,
	NM_PRD_RP            varchar(40)  NULL 
)
go



ALTER TABLE CA_PRD_RP
	ADD  PRIMARY KEY  CLUSTERED (ID_PRD_RP ASC)
go



CREATE TABLE CO_CD_RSN
( 
	CD_RSN               varchar(20)  NOT NULL ,
	CD_RSN_GRP           varchar(20)  NULL ,
	NM_RSN               varchar(40)  NULL ,
	DE_RC                varchar(4000)  NULL 
)
go



ALTER TABLE CO_CD_RSN
	ADD  PRIMARY KEY  CLUSTERED (CD_RSN ASC)
go



CREATE TABLE CO_CD_RSN_GRP
( 
	CD_RSN_GRP           varchar(20)  NOT NULL ,
	NM_RSN_GRP           varchar(40)  NULL ,
	DE_RSN_GRP           varchar(4000)  NULL 
)
go



ALTER TABLE CO_CD_RSN_GRP
	ADD  PRIMARY KEY  CLUSTERED (CD_RSN_GRP ASC)
go



CREATE TABLE CO_CTR_RVN_CST
( 
	ID_CTR_RVN_CST       integer  NOT NULL ,
	ID_BSNGP             integer  NULL ,
	ID_MRHRC_GP          integer  NULL ,
	NM_CTR_RVN_CST       varchar(40)  NULL 
)
go



ALTER TABLE CO_CTR_RVN_CST
	ADD  PRIMARY KEY  CLUSTERED (ID_CTR_RVN_CST ASC)
go



CREATE TABLE CO_CVN_UOM
( 
	CD_CVN_UOM_FM        varchar(20)  NOT NULL ,
	CD_CVN_UOM_TO        varchar(20)  NOT NULL ,
	MO_UOM_CVN           DECIMAL(9,2)  NULL 
		 DEFAULT  0
)
go



ALTER TABLE CO_CVN_UOM
	ADD  PRIMARY KEY  CLUSTERED (CD_CVN_UOM_FM ASC,CD_CVN_UOM_TO ASC)
go



CREATE TABLE CO_METAR_WTHR_CN
( 
	ID_METAR_WTHR_CN     char(32)  NOT NULL ,
	MN_CLD               char(2)  NULL ,
	YR_CLD               char(4)  NULL ,
	TS_UNVRSL_RP_TM      char(7)  NULL ,
	CD_ICAO              char(4)  NOT NULL ,
	CD_WTHR_CN_TYP       varchar(20)  NOT NULL ,
	DE_METAR_WTHR        varchar(255)  NULL ,
	CD_METAR_WND_CN      varchar(20)  NULL ,
	CD_METAR_VSBLTY      varchar(20)  NULL ,
	CD_METAR_WTHR_CN     varchar(20)  NULL ,
	CD_METAR_CLD_CN      char(4)  NULL ,
	QU_METAR_TEMP_DEW_PNT varchar(20)  NULL 
)
go



ALTER TABLE CO_METAR_WTHR_CN
	ADD  PRIMARY KEY  CLUSTERED (ID_METAR_WTHR_CN ASC)
go



ALTER TABLE CO_METAR_WTHR_CN
	ADD  UNIQUE (YR_CLD  ASC,MN_CLD  ASC,TS_UNVRSL_RP_TM  ASC,CD_ICAO  ASC)
go



CREATE TABLE CO_ST_INV
( 
	ID_ST_INV            integer  NOT NULL ,
	NM_ST_INV            varchar(40)  NULL 
)
go



ALTER TABLE CO_ST_INV
	ADD  PRIMARY KEY  CLUSTERED (ID_ST_INV ASC)
go



CREATE TABLE CO_UOM
( 
	CD_UOM               varchar(20)  NOT NULL ,
	TY_UOM               varchar(20)  NULL ,
	FL_UOM_ENG_MC        integer  NULL 
		CHECK  ( [FL_UOM_ENG_MC]=0 OR [FL_UOM_ENG_MC]=1 ),
	NM_UOM               varchar(40)  NULL ,
	DE_UOM               varchar(255)  NULL 
)
go



ALTER TABLE CO_UOM
	ADD  PRIMARY KEY  CLUSTERED (CD_UOM ASC)
go



CREATE TABLE DW3_DIM_APR
( 
	ID_ITM               char(32)  NOT NULL ,
	TY_ITM_STK           char(2)  NULL ,
	DE_STYL              varchar(255)  NULL ,
	NM_STYL              varchar(40)  NULL ,
	DE_SLH               varchar(255)  NULL ,
	DE_FBRC              varchar(255)  NULL ,
	CD_GND               varchar(20)  NULL ,
	DE_PTTRN             varchar(255)  NULL ,
	CD_APR_AG_GP         varchar(20)  NULL ,
	CD_APR_SN            varchar(20)  NULL ,
	DE_APR_CRE           varchar(255)  NULL ,
	DE_FRMLTY            varchar(255)  NULL ,
	NM_CLR               varchar(40)  NULL ,
	DE_CLR               varchar(255)  NULL ,
	DE_MDFR              varchar(255)  NULL ,
	NM_AGY_CLR_LST       varchar(40)  NULL ,
	NM_PLTE_CLR          varchar(40)  NOT NULL ,
	DE_PLTE_CLR          varchar(255)  NOT NULL ,
	CD_TB_SZ_NRF         char(2)  NULL ,
	NM_TB_SZ             varchar(40)  NULL ,
	DE_TYP_ACT_SZ        varchar(40)  NULL ,
	DE_PRPTN_ACT_SZ      varchar(255)  NULL ,
	NM_SZ_FMY            varchar(40)  NULL ,
	DE_SZ_FMY            varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_APR
	ADD  PRIMARY KEY  CLUSTERED (ID_ITM ASC)
go



CREATE TABLE DW3_DIM_BSN_UN_GEO_HIER
( 
	ID_GEO_LCN           char(32)  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	ID_GEO_SGMT_HRC      int  NOT NULL ,
	NM_BSN_UN            varchar(40)  NULL ,
	TY_BSN_UN            char(2)  NULL ,
	ID_BSNGP             int  NULL ,
	ID_STE               int  NULL ,
	CD_STE_TY            varchar(20)  NULL ,
	CD_CLMT_TYP          varchar(20)  NULL ,
	NM_GEO_SGMT_HRC      varchar(40)  NULL ,
	BSN_UN_GEO_LOC_GP_ID_TREE_PTH varchar(4000)  NULL ,
	BSN_UN_GEO_LOC_GP_NM_PTH varchar(4000)  NULL ,
	BSN_UN_GEO_LOC_HRC_LVL_PTH varchar(4000)  NULL ,
	BSN_UN_GEO_LOC_HRC_LVL_NM_PTH varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_BSN_UN_GEO_HIER
	ADD  PRIMARY KEY  CLUSTERED (ID_GEO_LCN ASC,ID_BSN_UN ASC,ID_GEO_SGMT_HRC ASC)
go



CREATE TABLE DW3_DIM_BSNGP
( 
	ID_BSNGP_FNC         int  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	NM_BSNGP_FNC         varchar(40)  NULL ,
	ID_BSNGP_LV          int  NULL ,
	ID_BSNGP_PRNT        int  NULL ,
	ID_BSNGP_CHLD        int  NOT NULL ,
	BSNGP_ID_HRC_TREE_PTH varchar(4000)  NULL ,
	BSNGP_HRC_LVL_PTH    varchar(4000)  NULL ,
	BSNGP_HRC_LVL_GP_NM_PTH varchar(4000)  NULL ,
	BSNGP_HRC_LVL_NM_PTH varchar(4000)  NULL ,
	CD_BSNGP_HRC         varchar(4)  NULL 
)
go



ALTER TABLE DW3_DIM_BSNGP
	ADD  PRIMARY KEY  CLUSTERED (ID_BSNGP_FNC ASC,ID_BSN_UN ASC)
go



CREATE TABLE DW3_DIM_BUSINESS_UNIT
( 
	ID_BSN_UN            char(32)  NOT NULL ,
	TY_BSN_UN            char(2)  NULL ,
	NM_BSN_UN            varchar(40)  NULL ,
	ID_CNY_LCL           int  NULL ,
	ID_PRTY_OPR          int  NULL ,
	ID_STE               int  NOT NULL ,
	ID_GEO_LCN           char(32)  NULL ,
	CD_TYP_CRDN_GEO      char(2)  NULL ,
	CD_CRDN_VL           varchar(30)  NULL ,
	CD_ICAO              char(4)  NULL ,
	CD_STE_TY            varchar(20)  NULL ,
	CD_TZ                char(6)  NULL ,
	ID_PRTY_OPR_STE      int  NULL ,
	A1_ADS               varchar(80)  NULL ,
	A2_ADS               varchar(80)  NULL ,
	A3_ADS               varchar(80)  NULL ,
	A4_ADS               varchar(80)  NULL ,
	CI_CNCT              varchar(30)  NULL ,
	ID_ISO_3166_2_CY_SBDVN int  NULL ,
	ID_PSTL_CD           char(32)  NULL ,
	ID_GEO_SGMT          int  NULL ,
	DC_OPN_RT_STR        date  NULL ,
	DC_CL_RT_STR         date  NULL ,
	DC_RMDL_LST          date  NULL ,
	QU_SZ_AR_SL          decimal(9,2)  NULL 
		 DEFAULT  0,
	QU_SZ_STR            decimal(9,2)  NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_DIM_BUSINESS_UNIT
	ADD  PRIMARY KEY  CLUSTERED (ID_BSN_UN ASC)
go



CREATE TABLE DW3_DIM_CA_HIER
( 
	ID_CLD               int  NOT NULL ,
	DC_DY_BSN            date  NOT NULL ,
	NM_CLD               varchar(40)  NULL ,
	ID_CLD_LV_PRNT       int  NULL ,
	ID_CLD_PRD_CHLD      int  NULL ,
	CLD_PRD_ID_TREE_PTH  varchar(4000)  NULL ,
	CLD_PRD_LVL_PTH      varchar(4000)  NULL ,
	CLD_PRD_LVL_NM_PTH   varchar(4000)  NULL ,
	CLD_PRD_NM_PTH       varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_CA_HIER
	ADD  PRIMARY KEY  CLUSTERED (ID_CLD ASC,DC_DY_BSN ASC)
go



CREATE TABLE DW3_DIM_CA_PRD_RP
( 
	ID_PRD_RP            int  NOT NULL ,
	DC_DY_BSN            date  NOT NULL ,
	NM_PRD_RP            varchar(40)  NULL ,
	ID_CLD               int  NOT NULL ,
	NM_CLD               varchar(40)  NULL ,
	ID_CLD_LV            int  NOT NULL ,
	ID_CLD_PRD           int  NOT NULL ,
	CLD_PRD_ID_TREE_PTH  varchar(4000)  NULL ,
	CLD_PRD_LVL_PTH      varchar(4000)  NULL ,
	CLD_PRD_HRC_LVL_NM_PTH varchar(4000)  NULL ,
	CLD_PRD_NM_PTH       varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_CA_PRD_RP
	ADD  PRIMARY KEY  CLUSTERED (ID_PRD_RP ASC,DC_DY_BSN ASC)
go



CREATE TABLE DW3_DIM_CHNL
( 
	ID_CHNL              int  NOT NULL ,
	DE_CHNL_DSCR         varchar(255)  NULL ,
	CD_TGT_TYP           varchar(20)  NULL ,
	CD_CNTN_ORG          varchar(20)  NULL ,
	CD_ON_LN_OFF_LN      varchar(20)  NULL ,
	CD_COM_MOD           varchar(20)  NULL ,
	NM_TCH_PNT           varchar(255)  NULL ,
	CD_PHY_DGTL          varchar(20)  NULL ,
	CD_MGD_TYP           varchar(20)  NULL ,
	NM_BSN_DMN           varchar(255)  NULL ,
	NA_BSN_DMN           varchar(4000)  NULL ,
	NM_PCS               varchar(255)  NULL ,
	NA_PCS               varchar(4000)  NULL ,
	DT_EF                datetime  NULL ,
	DT_EP                datetime  NULL ,
	NA_RMRK              varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_CHNL
	ADD  PRIMARY KEY  CLUSTERED (ID_CHNL ASC)
go



CREATE TABLE DW3_DIM_CT
( 
	ID_CT                int  NOT NULL ,
	FL_ANNYMS            int  NULL 
		CHECK  ( [FL_ANNYMS]=0 OR [FL_ANNYMS]=1 ),
	ID_CT_HSHLD          char(32)  NULL ,
	ID_KY_CT             int  NULL ,
	CD_PVCY_OOUT         char(2)  NULL ,
	DT_RGSTN             datetime  NULL ,
	ID_PRTY              int  NOT NULL ,
	CD_PRTY_TYP          varchar(20)  NULL ,
	NM_PRS_SLN           varchar(40)  NULL ,
	FN_PRS               varchar(40)  NULL ,
	TY_NM_FS             char(2)  NULL ,
	MD_PRS               varchar(40)  NULL ,
	TY_NM_MID            char(2)  NULL ,
	LN_PRS               varchar(40)  NULL ,
	TY_NM_LS             char(2)  NULL ,
	NM_PRS_SFX           varchar(40)  NULL ,
	NM_PRS_SR            varchar(40)  NULL ,
	NM_PRS_ML            varchar(40)  NULL ,
	NM_PRS_OFCL          varchar(40)  NULL ,
	ID_LGE               char(4)  NULL ,
	TY_GND_PRS           char(2)  NULL ,
	DC_PRS_BRT           date  NULL ,
	CD_ANN_INCM_RNGE     varchar(20)  NULL ,
	CD_MRTL_STS          varchar(20)  NULL ,
	CD_RC                varchar(20)  NULL ,
	CD_OCCPTN_TYP        varchar(20)  NULL ,
	CD_LF_STG            varchar(20)  NULL ,
	CD_ETHNC_TYP         varchar(20)  NULL ,
	CD_RLGN_FMY          varchar(20)  NULL ,
	NM_RLGN              varchar(20)  NULL ,
	CD_EDC_LV            varchar(20)  NULL ,
	CD_EMPLMT_STS        varchar(20)  NULL ,
	CD_PRSNLTY_TYP       varchar(20)  NULL ,
	CD_LFSTYL_TYP        varchar(20)  NULL ,
	CD_PRSL_VL_TYP       varchar(20)  NULL ,
	CD_VL_ATTD_LFSTL     varchar(20)  NULL ,
	CD_CNS_CR_SCOR       varchar(20)  NULL ,
	NM_CNS_CR_RTG_SV     varchar(40)  NULL ,
	CD_DTRY_HBT_TYP      varchar(20)  NULL ,
	CD_DSBLTY_IMPRMNT_TYP varchar(20)  NULL ,
	CD_ACTV_INTRST_1     varchar(20)  NULL ,
	CD_LSUR_PRFSL_TYP_1  varchar(20)  NULL ,
	CD_ACTV_INTRST_2     varchar(20)  NULL ,
	CD_LSUR_PRFSL_TYP_2  varchar(20)  NULL ,
	CD_ACTV_INTRST_3     varchar(20)  NULL ,
	CD_LSUR_PRFSL_TYP_3  varchar(20)  NULL ,
	CD_LGL_STS           varchar(20)  NULL ,
	NM_LGL               varchar(40)  NULL ,
	NM_TRD               varchar(40)  NULL ,
	DC_TRMN              date  NULL ,
	NM_JRDT_OF_INCRP     varchar(255)  NULL ,
	DC_INCRP             date  NULL ,
	CD_LGL_ORGN_TYP      varchar(20)  NULL ,
	DC_FSC_YR_END        date  NULL ,
	CD_BSN_ACTV          varchar(20)  NULL ,
	MO_LCL_ANN_RVN       decimal(16,5)  NULL 
		 DEFAULT  0,
	MO_GBL_ANN_RVN       decimal(16,5)  NULL 
		 DEFAULT  0,
	DC_OPN_FR_BSN        date  NULL ,
	DC_CLSD_FR_BSN       date  NULL ,
	ID_DUNS_NBR          char(9)  NULL ,
	FL_BNKRPTY           int  NULL 
		CHECK  ( [FL_BNKRPTY]=0 OR [FL_BNKRPTY]=1 ),
	DC_BNKRPTY           date  NULL ,
	DC_BNKRPTY_EMRGNC    date  NULL ,
	CD_BNKRPTY_TYP       varchar(20)  NULL ,
	QU_EM_CNT_LCL        integer  NULL ,
	QU_EM_CNT_GBL        integer  NULL ,
	CD_RTG_DUNN_AND_BRDST varchar(20)  NULL ,
	ID_LGE_PRMRY         char(4)  NULL ,
	NA_DE_ORGN           varchar(4000)  NULL ,
	A1_ADS               varchar(80)  NULL ,
	A2_ADS               varchar(80)  NULL ,
	A3_ADS               varchar(80)  NULL ,
	A4_ADS               varchar(80)  NULL ,
	CI_CNCT              varchar(30)  NULL ,
	ST_CNCT              char(2)  NULL ,
	ID_ISO_3166_2_CY_SBDVN integer  NULL ,
	ID_GEO_SGMT          integer  NULL ,
	PH_CMPL              varchar(32)  NULL ,
	EM_ADS_DMN_PRT       varchar(80)  NULL ,
	EM_ADS_LOC_PRT       varchar(80)  NULL ,
	ID_SCL_NTWRK         char(32)  NULL ,
	NM_SCL_NTWRK         varchar(40)  NULL ,
	ID_SCL_NTWRK_HNDL    char(32)  NULL ,
	ID_SCL_NTWRK_USR     varchar(255)  NULL 
)
go



ALTER TABLE DW3_DIM_CT
	ADD  PRIMARY KEY  CLUSTERED (ID_CT ASC)
go



CREATE TABLE DW3_DIM_CT_GEO_SGMT
( 
	ID_CT                int  NOT NULL ,
	ID_GEO_LCN           char(32)  NOT NULL ,
	ID_GEO_SGMT_HRC      int  NOT NULL ,
	ID_PRTY              int  NOT NULL ,
	ID_PRTY_RO_ASGMT     char(32)  NULL ,
	SC_RO_PRTY           char(2)  NULL ,
	CD_TYP_CNCT_MTH      char(6)  NULL ,
	CD_TYP_CNCT_PRPS     char(2)  NULL ,
	SC_PTY_CNCT_MTH      char(2)  NULL ,
	ID_ADS               int  NULL ,
	A1_ADS               varchar(80)  NULL ,
	A2_ADS               varchar(80)  NULL ,
	A3_ADS               varchar(80)  NULL ,
	A4_ADS               varchar(80)  NULL ,
	CD_ISO_3_CHR_CY      char(4)  NULL ,
	CD_ISO_CY_PRMRY_SBDVN_ABBR_CD char(6)  NULL ,
	NM_ISO_CY            varchar(40)  NULL ,
	NM_ISO_CY_PRMRY_SBDVN varchar(40)  NULL ,
	CI_CNCT              varchar(30)  NULL ,
	CD_PSTL              varchar(20)  NULL ,
	CD_PSTL_EXTN         char(4)  NULL ,
	DE_PSTL_CD           varchar(255)  NULL ,
	CD_TYP_CRDN_GEO      char(2)  NULL ,
	CD_CRDN_VL           varchar(30)  NULL ,
	NM_GEO_LCN           varchar(255)  NULL ,
	CD_CLMT_TYP          varchar(20)  NULL ,
	ID_GEO_SGMT_HRC_GP   char(32)  NULL ,
	NM_GEO_SGMT_HRC      varchar(40)  NULL ,
	IC_PRNT_HRC_LV_NMB   smallint  NULL ,
	CT_GEO_LCN_ID_HRC_TREE_PTH varchar(4000)  NULL ,
	CT_GEO_LCN_HRC_LVL_PTH varchar(4000)  NULL ,
	CT_GEO_LCN_HRC_GP_NM_PTH varchar(4000)  NULL ,
	CT_GEO_LCN_LVL_NM_PTH varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_CT_GEO_SGMT
	ADD  PRIMARY KEY  CLUSTERED (ID_CT ASC,ID_GEO_LCN ASC,ID_GEO_SGMT_HRC ASC)
go



CREATE TABLE DW3_DIM_CT_LYLTY
( 
	ID_CT                int  NOT NULL ,
	ID_CTAC              integer  NOT NULL ,
	ID_PRGM_LYLT         integer  NOT NULL ,
	NM_PRGM_LYLT         varchar(40)  NULL ,
	DE_PRGM_LYLT         varchar(4000)  NULL ,
	CD_LYLT_PRGM_RLTV_VL char(2)  NULL ,
	NM_LYLT_PRGRM_TR     varchar(40)  NULL ,
	NA_LYLT_PRGRM_TR     varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_CT_LYLTY
	ADD  PRIMARY KEY  CLUSTERED (ID_CT ASC,ID_CTAC ASC,ID_PRGM_LYLT ASC)
go



CREATE TABLE DW3_DIM_GEO_HRC_SGMT
( 
	ID_GEO_LCN           char(32)  NOT NULL ,
	ID_GEO_SGMT_HRC      int  NOT NULL ,
	NM_GEO_SGMT_HRC      varchar(40)  NULL ,
	IC_PRNT_HRC_LV_NMB   smallint  NULL ,
	ID_ST_SGMT_HRC_GP_CHLD char(32)  NULL ,
	ID_ST_SGMT_HRC_GP_PRNT char(32)  NULL ,
	GEO_LCN_ID_HRC_TREE_PTH varchar(4000)  NULL ,
	GEO_LCN_HRC_LVL_PTH  varchar(4000)  NULL ,
	GEO_LCN_HRC_LVL_GP_NM_PTH varchar(4000)  NULL ,
	GEO_LCN_HRC_LVL_NM_PTH varchar(4000)  NULL 
)
go



ALTER TABLE DW3_DIM_GEO_HRC_SGMT
	ADD  PRIMARY KEY  CLUSTERED (ID_GEO_LCN ASC,ID_GEO_SGMT_HRC ASC)
go



CREATE TABLE DW3_DIM_HSHLD
( 
	ID_HSHLD             char(32)  NOT NULL ,
	ID_PRTY              int  NOT NULL ,
	NM_HSHLD             varchar(255)  NULL ,
	CD_TYP_PRTY_AFLN     char(2)  NOT NULL ,
	SC_AFLN              char(2)  NULL ,
	DT_AFLN_EF           datetime  NULL ,
	DT_AFLN_EP           datetime  NULL ,
	CD_INVLVMNT_TYP      varchar(20)  NULL ,
	FL_PRCNPL_SUB_PRTY   int  NULL 
		CHECK  ( [FL_PRCNPL_SUB_PRTY]=0 OR [FL_PRCNPL_SUB_PRTY]=1 ),
	ID_PRTY_PRS          int  NULL ,
	NM_PRS_SLN           varchar(40)  NULL ,
	FN_PRS               varchar(40)  NULL ,
	MD_PRS               varchar(40)  NULL ,
	NM_PRS_ML            varchar(40)  NULL 
)
go



ALTER TABLE DW3_DIM_HSHLD
	ADD  PRIMARY KEY  CLUSTERED (ID_HSHLD ASC)
go



CREATE TABLE DW3_DIM_HSHLD_CNCT
( 
	ID_HSHLD             char(32)  NOT NULL ,
	CD_TYP_CNCT_MTH      char(6)  NOT NULL ,
	CD_TYP_CNCT_PRPS     char(2)  NOT NULL ,
	NM_HSHLD             varchar(255)  NULL ,
	FL_PRCNPL_SUB_PRTY   int  NULL ,
	ID_PRTY              int  NOT NULL ,
	NM_PRS_ML            varchar(40)  NULL ,
	ID_PRTY_RO_ASGMT     char(32)  NOT NULL ,
	TY_RO_PRTY           char(6)  NOT NULL ,
	SC_RO_PRTY           char(2)  NULL ,
	SC_PTY_CNCT_MTH      char(2)  NULL ,
	DC_EF                datetime  NULL ,
	DC_EP                datetime  NULL ,
	ID_ADS               int  NULL ,
	A1_ADS               varchar(80)  NULL ,
	A2_ADS               varchar(80)  NULL ,
	A3_ADS               varchar(80)  NULL ,
	A4_ADS               varchar(80)  NULL ,
	CI_CNCT              varchar(30)  NULL ,
	ST_CNCT              char(2)  NULL ,
	ID_PSTL_CD           char(32)  NULL ,
	ID_EM_ADS            int  NULL ,
	EM_ADS_DMN_PRT       varchar(80)  NULL ,
	EML_ADS_LOC_PRT      varchar(80)  NULL ,
	ID_PH                int  NULL ,
	PH_CMPL              varchar(32)  NULL ,
	ID_SCL_NTWRK_HNDL    char(32)  NULL ,
	ID_SCL_NTWRK         char(32)  NULL ,
	ID_SCL_NTWRK_USR     varchar(255)  NULL 
)
go



ALTER TABLE DW3_DIM_HSHLD_CNCT
	ADD  PRIMARY KEY  CLUSTERED (ID_HSHLD ASC,CD_TYP_CNCT_MTH ASC,CD_TYP_CNCT_PRPS ASC)
go



CREATE TABLE DW3_DIM_INVENTORY_LOCATION
( 
	ID_LCN               int  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	ID_STE               int  NOT NULL ,
	NM_LCN               varchar(40)  NULL ,
	QU_SZ_LCN            decimal(9,2)  NULL 
		 DEFAULT  0,
	LU_UOM_SZ            varchar(20)  NULL ,
	CD_FNC               char(4)  NULL ,
	CD_LCN_SCTY_CLS      char(6)  NULL 
)
go



ALTER TABLE DW3_DIM_INVENTORY_LOCATION
	ADD  PRIMARY KEY  CLUSTERED (ID_LCN ASC,ID_BSN_UN ASC)
go



CREATE TABLE DW3_DIM_ITM
( 
	ID_ITM               char(32)  NOT NULL ,
	NM_ITM               varchar(40)  NULL ,
	DE_ITM               varchar(255)  NULL ,
	DE_ITM_LNG           varchar(4000)  NULL ,
	TY_ITM               char(4)  NULL ,
	ID_MRHRC_GP          int  NULL ,
	NM_BRN               varchar(40)  NULL ,
	DE_BRN               varchar(255)  NULL ,
	CD_BRN_GRDG          varchar(20)  NULL ,
	NM_SUB_BRN           varchar(40)  NULL ,
	DE_SUB_BRN           varchar(255)  NULL ,
	LU_ITM_USG           char(2)  NULL ,
	LU_KT_ST             char(2)  NULL ,
	FL_ITM_SBST_IDN      int  NULL 
		CHECK  ( [FL_ITM_SBST_IDN]=0 OR [FL_ITM_SBST_IDN]=1 ),
	FL_FD_STP_ALW        int  NULL 
		CHECK  ( [FL_FD_STP_ALW]=0 OR [FL_FD_STP_ALW]=1 ),
	FL_CPN_ALW_MULTY     int  NULL 
		CHECK  ( [FL_CPN_ALW_MULTY]=0 OR [FL_CPN_ALW_MULTY]=1 ),
	FL_RTN_PRH           int  NULL 
		CHECK  ( [FL_RTN_PRH]=0 OR [FL_RTN_PRH]=1 ),
	FL_ITM_WIC           int  NULL 
		CHECK  ( [FL_ITM_WIC]=0 OR [FL_ITM_WIC]=1 ),
	QU_MNM_SLS_UN        decimal(3,0)  NULL 
		 DEFAULT  0,
	QU_UN_BLK_MXM        decimal(3,0)  NULL 
		 DEFAULT  0,
	TY_ITM_STK           char(2)  NULL ,
	CD_UOM               varchar(20)  NULL ,
	LU_CNT_SLS_WT_UN     char(2)  NULL ,
	FA_PRC_UN_STK_ITM    decimal(9,2)  NULL 
		 DEFAULT  0,
	CD_UOM_RTL_PKG_SZ    varchar(20)  NULL ,
	TY_ENV_STK_ITM       char(2)  NULL ,
	TY_SCTY_RQ           char(2)  NULL ,
	TY_MTR_HZ_STK_ITM    char(2)  NULL ,
	CP_UN_SL_LS_RCV_BS   decimal(16,5)  NULL 
		 DEFAULT  0,
	CP_CST_NT_LS_RCV     decimal(16,5)  NULL 
		 DEFAULT  0,
	DC_CST_EST_LS_RCV    date  NULL ,
	LU_STYL              char(4)  NULL ,
	CD_CLR               char(4)  NULL ,
	ID_SZ_FMY            int  NULL ,
	CD_SZ                char(6)  NULL ,
	DC_AVLB_FR_SLS       date  NULL ,
	LU_MTH_INV_ACNT      char(2)  NULL ,
	LU_WRTY_STR_SRZ      char(4)  NULL ,
	LU_WRTY_MF_SRZ_ITM   char(4)  NULL ,
	DE_SZ_MF_SRZ_ITM     varchar(255)  NULL ,
	CY_MDL_SRZ_ITM       char(4)  NULL ,
	NM_NMB_SRZ_ITM       varchar(40)  NULL ,
	DE_CLR_MF_SRZ_ITM    varchar(255)  NULL ,
	URI_LNK              varchar(255)  NULL ,
	NM_LNK_FLE           varchar(255)  NULL ,
	CD_LNK_TYP           varchar(255)  NULL ,
	FL_SHRBL             int  NULL 
		CHECK  ( [FL_SHRBL]=0 OR [FL_SHRBL]=1 ),
	NM_ITM_TTL           varchar(255)  NULL ,
	ID_OPR_SYS           char(32)  NULL ,
	CD_FLE_FRMT_TYP      varchar(20)  NULL ,
	TY_ITM_SV            char(2)  NULL ,
	LU_TRM_SV            char(2)  NULL ,
	CP_BS_SV_ITM         decimal(16,5)  NULL 
		 DEFAULT  0,
	CP_NT_SV_ITM         decimal(16,5)  NULL 
		 DEFAULT  0,
	DC_CST_EST_SV_ITM    date  NULL ,
	TY_PR_RNT            char(2)  NULL ,
	QU_PR_RNT            decimal(3,0)  NULL 
		 DEFAULT  0,
	MO_DS_RNT_SV         decimal(16,5)  NULL 
		 DEFAULT  0,
	PE_DS_RNT_SV         decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_PNTY              decimal(16,5)  NULL 
		 DEFAULT  0,
	PE_PNTY              decimal(7,4)  NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_DIM_ITM
	ADD  PRIMARY KEY  CLUSTERED (ID_ITM ASC)
go



CREATE TABLE DW3_DIM_MDSE_HIER
( 
	id_mrhrc_fnc         int  NOT NULL ,
	ID_ITM               char(32)  NOT NULL ,
	NM_MRHRC_FNC         varchar(255)  NULL ,
	id_mrhrc_lv_prnt     int  NULL ,
	id_mrhrc_gp_chld     int  NULL ,
	id_mrhrc_gp_prnt     int  NULL ,
	MRCHRC_ID_TREE_PTH   varchar(4000)  NULL ,
	MRHRC_LVL_PTH        varchar(4000)  NULL ,
	MRHRC_LV_NM_PTH      varchar(4000)  NULL ,
	MRHRC_LVL_GP_NM_PTH  varchar(4000)  NULL ,
	CD_MRHRC_ROOT        varchar(4)  NULL ,
	ITM_ID_NM            varchar(75)  NULL 
)
go



ALTER TABLE DW3_DIM_MDSE_HIER
	ADD  PRIMARY KEY  CLUSTERED (id_mrhrc_fnc ASC,ID_ITM ASC)
go



CREATE TABLE DW3_DIM_PROMOTION
( 
	ID_PRM_OFR           int  NOT NULL ,
	ID_BSNGP             int  NULL ,
	NM_PRM_OPR           varchar(40)  NOT NULL ,
	NM_PRM_CT            varchar(40)  NOT NULL ,
	NM_PRM_PRT           varchar(40)  NOT NULL ,
	DT_PRM_EF            datetime  NULL ,
	DT_PRM_EP            datetime  NULL ,
	CD_STS_PRM           char(18)  NULL ,
	TY_UP_SELL           char(2)  NOT NULL ,
	TY_CNCRN             char(2)  NOT NULL ,
	ID_RU_PRDV           int  NULL ,
	ID_EL_PRDV           int  NULL ,
	DE_PRM_PRDV          varchar(255)  NULL ,
	ID_CMPGN             char(32)  NOT NULL ,
	NM_CMPGN             varchar(255)  NULL ,
	CD_STS_CMPGN         char(2)  NULL ,
	NM_PRM               varchar(255)  NULL ,
	ID_PRML_INITV        int  NOT NULL ,
	NM_PRML_INITV        varchar(255)  NULL ,
	NA_PRML_INITV        varchar(4000)  NULL ,
	CD_PRML_TYP          varchar(20)  NULL ,
	DT_EF                datetime  NULL ,
	DT_EP                datetime  NULL ,
	CD_STS_PRML_INITV    char(2)  NULL ,
	NM_HLDY              varchar(40)  NULL ,
	DE_HLDY              varchar(255)  NULL ,
	CD_RLGN_FMY          varchar(20)  NULL ,
	NM_RLGN              varchar(20)  NULL ,
	CD_SCLR_CLBRTN_EV    varchar(20)  NULL ,
	CD_CY_ISO            char(2)  NULL 
)
go



ALTER TABLE DW3_DIM_PROMOTION
	ADD  PRIMARY KEY  CLUSTERED (ID_PRM_OFR ASC)
go



CREATE TABLE DW3_DIM_ST_ASCTN_RTL_TRN_CA
( 
	ID_TRN               char(32)  NOT NULL ,
	IC_LN_ITM            smallint  NOT NULL ,
	ID_CLD               int  NOT NULL ,
	DC_DY_BSN            date  NOT NULL 
)
go



ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_CA
	ADD  PRIMARY KEY  CLUSTERED (ID_TRN ASC,IC_LN_ITM ASC,ID_CLD ASC,DC_DY_BSN ASC)
go



CREATE TABLE DW3_DIM_ST_ASCTN_RTL_TRN_RP
( 
	ID_TRN               char(32)  NOT NULL ,
	IC_LN_ITM            smallint  NOT NULL ,
	ID_PRD_RP            int  NOT NULL ,
	DC_DY_BSN            date  NOT NULL 
)
go



ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_RP
	ADD  PRIMARY KEY  CLUSTERED (ID_TRN ASC,IC_LN_ITM ASC,ID_PRD_RP ASC,DC_DY_BSN ASC)
go



CREATE TABLE DW3_FACT_CT_LYLTY_BEHAVIOR
( 
	ID_TRN               char(32)  NOT NULL ,
	IC_LN_ITM            smallint  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	DC_DY_BSN            date  NOT NULL ,
	ID_WS                char(32)  NOT NULL ,
	ID_OPR               char(32)  NOT NULL ,
	FL_CNCL              int  NULL 
		CHECK  ( [FL_CNCL]=0 OR [FL_CNCL]=1 ),
	FL_VD                int  NULL 
		CHECK  ( [FL_VD]=0 OR [FL_VD]=1 ),
	FL_SPN               int  NULL 
		CHECK  ( [FL_SPN]=0 OR [FL_SPN]=1 ),
	FL_TRG_TRN           int  NULL 
		CHECK  ( [FL_TRG_TRN]=0 OR [FL_TRG_TRN]=1 ),
	ID_CT                int  NULL ,
	ID_CHNL              int  NULL ,
	CD_RTL_SHPPG_TRP_TYP varchar(20)  NULL ,
	QU_UN_RTL_TRN        decimal(7,0)  NULL 
		 DEFAULT  0,
	ID_RPSTY_TND         int  NULL ,
	CD_CNY_ISO_4217      int  NULL ,
	TR_LTM_RDM_ID_PRGM_LYLT int  NULL ,
	TR_LTM_RDM_ID_CTAC   int  NULL ,
	TR_LTM_RDM_IC_MDFR_RT_PRC smallint  NULL ,
	TR_LTM_RDM_ID_PDT_PRM decimal(16,5)  NULL 
		 DEFAULT  0,
	TR_LTM_RDM_QU_PNT_RDMD integer  NULL ,
	TR_LTM_RDM_ID_LYLT_PNT_ERN_DRVN_RU int  NULL ,
	TR_LTM_RDM_ID_PRM_OFR int  NULL ,
	TR_LTM_RDM_ID_PRML_INITV int  NULL ,
	TR_LTM_RDM_ID_RU_PRDV int  NULL ,
	TR_LTM_RDM_ID_EL_PRDV int  NULL ,
	TR_LTM_RDM_PE_MDFR_RT_PRC decimal(7,4)  NULL 
		 DEFAULT  0,
	TR_LTM_RDM_MO_MDFR_RT_PRC decimal(16,5)  NULL 
		 DEFAULT  0,
	TR_LTM_RDM_MO_PRV_PRC decimal(7,2)  NULL 
		 DEFAULT  0,
	TR_LTM_RDM_CD_MTH_CLC char(4)  NULL ,
	TR_LTM_RDM_CD_MTH_ADJT char(2)  NULL ,
	TR_LTM_RDM_MO_NW_PRC decimal(7,2)  NULL 
		 DEFAULT  0,
	TR_LTM_RDM_CD_MDF_BNFT char(4)  NULL ,
	TR_LTM_RDM_DE_MDFR_RTL_PRC varchar(255)  NULL ,
	TR_RDM_ID_PRM_OFR    int  NULL ,
	TR_RDM_ID_PRML_INITV int  NULL ,
	TR_RDM_ID_RU_PRDV    int  NULL ,
	TR_RDM_ID_EL_PRDV    int  NULL ,
	TR_RDM_PE_MDF        decimal(7,4)  NULL 
		 DEFAULT  0,
	TR_RDM_MO_MDF        decimal(16,5)  NULL 
		 DEFAULT  0,
	TR_RDM_MO_PRC_MDFN_BS_AMT decimal(7,2)  NULL 
		 DEFAULT  0,
	TR_RDM_DE_TR_LTM_MDF varchar(255)  NULL ,
	TR_LTM_ERN_ID_PRGM_LYLT int  NULL ,
	TR_LTM_ERN_ID_CTAC   int  NULL ,
	TR_LTM_ERN_QU_PNT_ERN integer  NULL ,
	TR_LTM_ERN_ID_LYLT_PNT_ERN_DRVN_RU int  NULL ,
	TR_LTM_ERN_ID_LYLT_PNT_ERN_EL_RU int  NULL ,
	TR_LTM_ERN_CD_LYLT_PRGM_RLTV_VL char(2)  NULL ,
	PRML_QU_RWD_PNT_ERN  int  NULL ,
	PRML_ID_PRM_OFR      int  NULL ,
	PRML_ID_RU_PRDV      int  NULL ,
	PRML_ID_EL_PRDV      int  NULL ,
	PRML_ID_PRML_INITV   int  NULL 
)
go



ALTER TABLE DW3_FACT_CT_LYLTY_BEHAVIOR
	ADD  PRIMARY KEY  CLUSTERED (ID_TRN ASC,IC_LN_ITM ASC)
go



CREATE TABLE DW3_FACT_INVENTORY
( 
	ID_ITM               char(32)  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	ID_LCN               int  NOT NULL ,
	ID_ST_INV            integer  NOT NULL ,
	ID_CTR_RVN_CST       integer  NOT NULL ,
	ID_PRD_RP            integer  NOT NULL ,
	ID_PRD_RP_CLD        int  NOT NULL ,
	DC_INV_FS_RCPT       date  NULL ,
	DC_INV_LS_RCPT       date  NULL ,
	MO_UN_RTL            decimal(7,2)  NOT NULL 
		 DEFAULT  0,
	MO_UN_CST            decimal(16,5)  NULL 
		 DEFAULT  0,
	QU_ON_ORD_CNT        decimal(38,2)  NULL ,
	MO_ON_ORD_CST        decimal(38,7)  NULL ,
	MO_ON_ORD_RTL_AMT    decimal(38,4)  NULL ,
	QU_INTRST_CNT        decimal(38,2)  NULL ,
	MO_INTRST_CST        decimal(38,7)  NULL ,
	MO_INTRST_RTL        decimal(38,4)  NULL ,
	CD_MKD_CYCL          char(4)  NULL ,
	QU_DSC_ITM           decimal(9,2)  NULL 
		 DEFAULT  0,
	QU_BGN               decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_RCV               decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_TSF_IN            decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_TSF_OT            decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_ADJT              decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_RTN               decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_SLS               decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_RTV               decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	QU_END               decimal(9,2)  NOT NULL 
		 DEFAULT  0,
	CP_UN_AV_WT_BGN      decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	CP_UN_AV_WT_END      decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	TC_RCV_CM            decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	TP_RCV               decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_VL_BGN            decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_MKN_CM            decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	PE_MKN_CM            decimal(7,4)  NOT NULL 
		 DEFAULT  0,
	TP_SLS_GS_CM         decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	TP_RTN               decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_TSF_IN_CM         decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_TSF_OT_CM         decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	TP_RTN_TO_VN         decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_ADJT_RT_CM        decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_MKD_PRN_CM        decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_MKD_TMP_CM        decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_MKP_PRN_CM        decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_MKP_TMP_CM        decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_DSC_EM_CM         decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_DPC_DM_CM_ITM     decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_DPC_OT_OF_DT      decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_VL_END            decimal(16,5)  NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_FACT_INVENTORY
	ADD  PRIMARY KEY  CLUSTERED (ID_ITM ASC,ID_BSN_UN ASC,ID_LCN ASC,ID_ST_INV ASC,ID_CTR_RVN_CST ASC,ID_PRD_RP ASC)
go



CREATE TABLE DW3_FACT_SALE_RTN_BEHAVIOR
( 
	ID_TRN               char(32)  NOT NULL ,
	IC_LN_ITM            smallint  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	ID_LCN               int  NULL ,
	DC_DY_BSN            date  NOT NULL ,
	ID_WS                char(32)  NOT NULL ,
	ID_OPR               char(32)  NOT NULL ,
	FL_CNCL              int  NULL 
		CHECK  ( [FL_CNCL]=0 OR [FL_CNCL]=1 ),
	FL_VD                int  NULL 
		CHECK  ( [FL_VD]=0 OR [FL_VD]=1 ),
	FL_SPN               int  NULL 
		CHECK  ( [FL_SPN]=0 OR [FL_SPN]=1 ),
	FL_TRG_TRN           int  NULL 
		CHECK  ( [FL_TRG_TRN]=0 OR [FL_TRG_TRN]=1 ),
	ID_METAR_WTHR_CN     char(32)  NULL ,
	ID_METAR_WTHR_FRCST  char(32)  NULL ,
	ID_CT                int  NULL ,
	ID_CHNL              integer  NULL ,
	CD_RTL_SHPPG_TRP_TYP varchar(20)  NULL ,
	QU_UN_RTL_TRN        decimal(7,0)  NULL 
		 DEFAULT  0,
	ID_RPSTY_TND         int  NULL ,
	CD_CNY_ISO_4217      char(3)  NULL ,
	ID_ITM               char(32)  NULL ,
	ID_ITM_PS_QFR        int  NULL ,
	ID_ITM_PS            varchar(14)  NULL ,
	ID_ITM_UN_TRC        char(32)  NULL ,
	MO_PRC_REG           decimal(7,2)  NULL 
		 DEFAULT  0,
	UN_UPRQY_REG         decimal(9,2)  NULL 
		 DEFAULT  0,
	UN_UPRQY_ACT         decimal(9,2)  NULL 
		 DEFAULT  0,
	QU_ITM_LM_RTN_SLS    decimal(9,2)  NULL 
		 DEFAULT  0,
	QU_UN                decimal(9,2)  NULL 
		 DEFAULT  0,
	MO_EXTND             decimal(16,5)  NULL 
		 DEFAULT  0,
	MO_DSC_UN            decimal(7,2)  NULL 
		 DEFAULT  0,
	MO_DSC_UN_EXT        decimal(7,2)  NULL 
		 DEFAULT  0,
	LU_PRC_RT_DRVN       char(4)  NULL ,
	LU_ACTN_CD           char(2)  NULL ,
	CD_RSN               varchar(20)  NULL ,
	CP_UN                decimal(16,5)  NULL 
		 DEFAULT  0,
	UN_UPRQY             decimal(9,2)  NULL 
		 DEFAULT  0,
	RP_MSRP              decimal(7,2)  NULL 
		 DEFAULT  0,
	UN_MSRP_UPRQY        decimal(9,2)  NULL 
		 DEFAULT  0,
	CP_INV               decimal(16,5)  NULL 
		 DEFAULT  0,
	UN_INV_UPRQY         decimal(9,2)  NULL 
		 DEFAULT  0,
	ID_STR_ISSG          char(32)  NULL ,
	ID_NMB_SRZ_GF_CF     char(32)  NULL ,
	ID_RU_PRDV           int  NULL ,
	ID_EL_PRDV           int  NULL ,
	FL_PRRT              int  NULL 
		CHECK  ( [FL_PRRT]=0 OR [FL_PRRT]=1 ),
	PE_MDF               decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_MDF               decimal(16,5)  NULL 
		 DEFAULT  0,
	MO_PRC_MDFN_BS_AMT   decimal(7,2)  NULL 
		 DEFAULT  0,
	DE_TR_LTM_MDF        varchar(255)  NULL ,
	MO_TRN_LVL_DSCNT     decimal(16,5)  NULL ,
	ID_PRM_OFR_1         int  NULL ,
	ID_PRML_INITV_1      int  NULL ,
	ID_RU_PRDV_1         int  NULL ,
	ID_EL_PRDV_1         int  NULL ,
	MO_PRV_PRC_1         decimal(7,2)  NULL 
		 DEFAULT  0,
	PE_MDFR_RT_PRC_1     decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_MDFR_RT_PRC_1     decimal(16,5)  NULL 
		 DEFAULT  0,
	CD_MTH_CLC_1         char(4)  NULL ,
	CD_MTH_ADJT_1        char(2)  NULL ,
	MO_NW_PRC_1          decimal(7,2)  NULL 
		 DEFAULT  0,
	CD_MDF_BNFT_1        char(4)  NULL ,
	DE_MDFR_RTL_PRC_1    varchar(255)  NULL ,
	PE_TR_LTM_MDF_PRRT_1 decimal(7,4)  NULL 
		 DEFAULT  0,
	CD_RSN_1             varchar(20)  NULL ,
	ID_PRM_OFR_2         int  NULL ,
	ID_PRML_INITV_2      int  NULL ,
	ID_RU_PRDV_2         int  NULL ,
	ID_EL_PRDV_2         int  NULL ,
	MO_PRV_PRC_2         decimal(7,2)  NULL 
		 DEFAULT  0,
	PE_MDFR_RT_PRC_2     decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_MDFR_RT_PRC_2     decimal(16,5)  NULL 
		 DEFAULT  0,
	CD_MTH_CLC_2         char(4)  NULL ,
	CD_MTH_ADJT_2        char(2)  NULL ,
	MO_NW_PRC_2          decimal(7,2)  NULL 
		 DEFAULT  0,
	CD_MDF_BNFT_2        char(4)  NULL ,
	DE_MDFR_RTL_PRC_2    varchar(255)  NULL ,
	PE_TR_LTM_MDF_PRRT_2 decimal(7,4)  NULL 
		 DEFAULT  0,
	CD_RSN_2             varchar(20)  NULL ,
	ID_PRM_OFR_3         int  NULL ,
	ID_PRML_INITV_3      int  NULL ,
	ID_RU_PRDV_3         int  NULL ,
	ID_EL_PRDV_3         int  NULL ,
	MO_PRV_PRC_3         decimal(7,2)  NULL 
		 DEFAULT  0,
	PE_MDFR_RT_PRC_3     decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_MDFR_RT_PRC_3     decimal(16,5)  NULL 
		 DEFAULT  0,
	CD_MTH_CLC_3         char(4)  NULL ,
	CD_MTH_ADJT_3        char(2)  NULL ,
	MO_NW_PRC_3          decimal(7,2)  NULL 
		 DEFAULT  0,
	CD_MDF_BNFT_3        char(4)  NULL ,
	DE_MDFR_RTL_PRC_3    varchar(255)  NULL ,
	PE_TR_LTM_MDF_PRRT_3 decimal(7,4)  NULL 
		 DEFAULT  0,
	CD_RSN_3             varchar(20)  NULL ,
	ID_PRM_OFR_4         int  NULL ,
	ID_PRML_INITV_4      int  NULL ,
	ID_RU_PRDV_4         int  NULL ,
	ID_EL_PRDV_4         int  NULL ,
	MO_PRV_PRC_4         decimal(7,2)  NULL 
		 DEFAULT  0,
	PE_MDFR_RT_PRC_4     decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_MDFR_RT_PRC_4     decimal(16,5)  NULL 
		 DEFAULT  0,
	CD_MTH_CLC_4         char(4)  NULL ,
	CD_MTH_ADJT_4        char(2)  NULL ,
	MO_NW_PRC_4          decimal(7,2)  NULL 
		 DEFAULT  0,
	CD_MDF_BNFT_4        char(4)  NULL ,
	DE_MDFR_RTL_PRC_4    varchar(255)  NULL ,
	PE_TR_LTM_MDF_PRRT_4 decimal(7,4)  NULL 
		 DEFAULT  0,
	CD_RSN_4             varchar(20)  NULL ,
	ID_PRM_OFR_5         int  NULL ,
	ID_PRML_INITV_5      int  NULL ,
	ID_RU_PRDV_5         int  NULL ,
	ID_EL_PRDV_5         int  NULL ,
	MO_PRV_PRC_5         decimal(7,2)  NULL 
		 DEFAULT  0,
	PE_MDFR_RT_PRC_5     decimal(7,4)  NULL 
		 DEFAULT  0,
	MO_MDFR_RT_PRC_5     decimal(16,5)  NULL 
		 DEFAULT  0,
	CD_MTH_CLC_5         char(4)  NULL ,
	CD_MTH_ADJT_5        char(2)  NULL ,
	MO_NW_PRC_5          decimal(7,2)  NULL 
		 DEFAULT  0,
	CD_MDF_BNFT_5        char(4)  NULL ,
	DE_MDFR_RTL_PRC_5    varchar(255)  NULL ,
	PE_TR_LTM_MDF_PRRT_5 decimal(7,4)  NULL 
		 DEFAULT  0,
	CD_RSN_5             varchar(20)  NULL 
)
go



ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  PRIMARY KEY  CLUSTERED (ID_TRN ASC,IC_LN_ITM ASC)
go



CREATE TABLE DW3_FACT_SMP_CR_DB_CRD_SPND
( 
	ID_CT_RP_PRD_SPND    integer  NOT NULL ,
	ID_PRD_RP            integer  NOT NULL ,
	ID_CT                int  NOT NULL ,
	ID_TND_MD_COSPNSR    char(32)  NULL ,
	TY_TND               varchar(20)  NULL ,
	MO_CR_DB_TOT         decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	ID_TND_MD_BRN        char(32)  NULL ,
	ID_PYM_SV_PVR        char(32)  NULL ,
	ID_ISSR_TND_CRD      char(6)  NULL ,
	TY_CRD               char(6)  NULL ,
	NM_CRD_HLD           varchar(40)  NULL ,
	DC_EP_CRD            char(4)  NULL 
)
go



ALTER TABLE DW3_FACT_SMP_CR_DB_CRD_SPND
	ADD  PRIMARY KEY  CLUSTERED (ID_CT_RP_PRD_SPND ASC)
go



CREATE TABLE DW3_FACT_TENDER_BEHAVIOR
( 
	ID_TRN               char(32)  NOT NULL ,
	IC_LN_ITM            smallint  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	DC_DY_BSN            date  NOT NULL ,
	ID_WS                char(32)  NOT NULL ,
	ID_OPR               char(32)  NOT NULL ,
	FL_CNCL              int  NULL 
		CHECK  ( [FL_CNCL]=0 OR [FL_CNCL]=1 ),
	FL_VD                int  NULL 
		CHECK  ( [FL_VD]=0 OR [FL_VD]=1 ),
	FL_SPN               int  NULL 
		CHECK  ( [FL_SPN]=0 OR [FL_SPN]=1 ),
	FL_TRG_TRN           int  NULL 
		CHECK  ( [FL_TRG_TRN]=0 OR [FL_TRG_TRN]=1 ),
	ID_CT                int  NULL ,
	ID_CHNL              int  NULL ,
	CD_RTL_SHPPG_TRP_TYP varchar(20)  NULL ,
	QU_UN_RTL_TRN        decimal(7,0)  NULL 
		 DEFAULT  0,
	ID_RPSTY_TND         int  NULL ,
	CD_CNY_ISO_4217      char(3)  NULL ,
	TY_TND               varchar(20)  NULL ,
	FL_CO_PAY            int  NULL 
		CHECK  ( [FL_CO_PAY]=0 OR [FL_CO_PAY]=1 ),
	MO_TRN_AMT           decimal(7,2)  NOT NULL 
		 DEFAULT  0,
	CD_CNY_ISO_4217_TND  char(3)  NULL ,
	TND_DNM_ID           int  NULL ,
	TND_DNM_QU           decimal(9,2)  NULL 
		 DEFAULT  0,
	CD_CNY_ISO_4217_LCL  char(3)  NULL ,
	MO_RT_TO_BUY         decimal(14,9)  NULL ,
	MO_RT_TO_SL          decimal(14,9)  NULL ,
	MO_FE_SV_EXC         decimal(16,5)  NULL 
		 DEFAULT  0,
	DC_RT_EXC_EF         date  NULL ,
	DC_RT_EXC_EP         date  NULL ,
	CSH_MO_TRN_AMT       decimal(7,2)  NULL 
		 DEFAULT  0,
	CSH_MO_FRG_CY        decimal(7,2)  NULL 
		 DEFAULT  0,
	CSH_MO_RTE_EXC       decimal(16,5)  NULL 
		 DEFAULT  0,
	CSH_MO_ITM_LN_TND    decimal(16,5)  NULL 
		 DEFAULT  0,
	CHG_MO_TRN_AMT       decimal(7,2)  NULL 
		 DEFAULT  0,
	CHG_MO_FRG_CY        decimal(7,2)  NULL 
		 DEFAULT  0,
	CHG_MO_RTE_EXC       decimal(16,5)  NULL 
		 DEFAULT  0,
	CHG_MO_ITM_LN_TND    decimal(16,5)  NULL 
		 DEFAULT  0,
	CHK_MO_TRN_AMT       decimal(7,2)  NULL 
		 DEFAULT  0,
	CHK_MO_FRG_CY        decimal(7,2)  NULL 
		 DEFAULT  0,
	CHK_MO_RTE_EXC       decimal(16,5)  NULL 
		 DEFAULT  0,
	CHK_MO_ITM_LN_TND    decimal(16,5)  NULL 
		 DEFAULT  0,
	CHK_ID_TND_MD_BRN    char(32)  NULL ,
	ID_BK_CHK            int  NULL ,
	ID_ACNT_CHK          int  NULL ,
	ID_ADJN_CHK          char(4)  NULL ,
	ID_CRD_CHK           varchar(40)  NULL ,
	CRDB_MO_TRN_AMT      decimal(7,2)  NULL 
		 DEFAULT  0,
	CRDB_MO_FRG_CY       decimal(7,2)  NULL 
		 DEFAULT  0,
	CRDB_MO_RTE_EXC      decimal(16,5)  NULL 
		 DEFAULT  0,
	CRDB_MO_ITM_LN_TND   decimal(16,5)  NULL 
		 DEFAULT  0,
	CRDB_ID_TND_MD_BRN   char(32)  NULL ,
	CRDB_TY_CRD          char(6)  NULL ,
	CRDB_ID_ISSR_TND_CRD char(6)  NULL ,
	LU_ADJN_CRDB         char(6)  NULL ,
	CPN_MO_TRN_AMT       decimal(7,2)  NULL 
		 DEFAULT  0,
	CPN_MO_FRG_CY        decimal(7,2)  NULL 
		 DEFAULT  0,
	CPN_MO_RTE_EXC       decimal(16,5)  NULL 
		 DEFAULT  0,
	CPN_MO_ITM_LN_TND    decimal(16,5)  NULL 
		 DEFAULT  0,
	CPN_IC_LN_ITM_VLD    smallint  NULL ,
	CPN_ID_MF            int  NULL ,
	CPN_FC_FMY_MF        char(3)  NULL ,
	CPN_LU_CPN_PRM       char(6)  NULL ,
	CPN_DC_EP            varchar(20)  NULL ,
	CPN_QY               decimal(9,2)  NULL 
		 DEFAULT  0,
	CPN_TY               char(4)  NULL ,
	GF_CF_MO_TRN_AMT     decimal(7,2)  NULL 
		 DEFAULT  0,
	GF_CF_MO_FRG_CY      decimal(7,2)  NULL 
		 DEFAULT  0,
	GF_CF_MO_RTE_EXC     decimal(16,5)  NULL 
		 DEFAULT  0,
	GF_CF_MO_ITM_LN_TND  decimal(16,5)  NULL 
		 DEFAULT  0,
	GF_CF_ID_STR_ISSG    char(32)  NULL ,
	GF_CF_ID_NMB_SRZ_GF_CF char(32)  NULL ,
	GF_CF_MO_UNSP        decimal(16,5)  NULL 
		 DEFAULT  0,
	CTAC_MO_TRN_AMT      decimal(7,2)  NULL 
		 DEFAULT  0,
	CTAC_MO_FRG_CY       decimal(7,2)  NULL 
		 DEFAULT  0,
	CTAC_MO_RTE_EXC      decimal(16,5)  NULL 
		 DEFAULT  0,
	CTAC_MO_ITM_LN_TND   decimal(16,5)  NULL 
		 DEFAULT  0,
	CTAC_ID_CTAC         int  NULL ,
	CTAC_TY_CTAC         char(2)  NULL ,
	CTAC_CD_CR_STS       varchar(20)  NULL ,
	CTAC_ID_INVC         int  NULL ,
	CTAC_ID_CT_RPS       int  NULL ,
	AI_ACNT_CT_CRD       varchar(20)  NULL ,
	TRADEIN_MO_TRN_AMT   decimal(7,2)  NULL 
		 DEFAULT  0,
	TRADEIN_MO_FRG_CY    decimal(7,2)  NULL 
		 DEFAULT  0,
	TRADEIN_MO_RTE_EXC   decimal(16,5)  NULL 
		 DEFAULT  0,
	TRADEIN_MO_ITM_LN_TND decimal(16,5)  NULL 
		 DEFAULT  0,
	TRADEIN_TY_TRD_IN    char(2)  NULL ,
	EBT_MO_TRN_AMT       decimal(7,2)  NULL 
		 DEFAULT  0,
	EBT_MO_FRG_CY        decimal(7,2)  NULL 
		 DEFAULT  0,
	EBT_MO_RTE_EXC       decimal(16,5)  NULL 
		 DEFAULT  0,
	EBT_MO_ITM_LN_TND    decimal(16,5)  NULL 
		 DEFAULT  0,
	EBT_ID_FDL           varchar(40)  NULL ,
	EBT_UN_SRZ           varchar(40)  NULL ,
	EBT_MO_CHG           decimal(7,2)  NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_FACT_TENDER_BEHAVIOR
	ADD  PRIMARY KEY  CLUSTERED (ID_TRN ASC,IC_LN_ITM ASC)
go



CREATE TABLE DW3_STRD_SMRY_BSN_UN_QTRLY_NET
( 
	ID_BSN_UN            char(32)  NOT NULL ,
	NRF_454_YR_QTR       varchar(255)  NULL ,
	MO_BSN_UN_QTR_NET_SLS decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_BSN_UN_QTR_NET_MRGN decimal(16,5)  NOT NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_STRD_SMRY_BSN_UN_QTRLY_NET
	ADD  PRIMARY KEY  CLUSTERED (ID_BSN_UN ASC)
go



CREATE TABLE DW3_STRD_SMRY_CT_SLSRTN
( 
	ID_CT                char(32)  NOT NULL ,
	ID_TRN               char(32)  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	DC_DY_BSN            date  NOT NULL ,
	ID_CHNL              int  NOT NULL ,
	QU_LN_ITM            integer  NULL ,
	MO_NT_SLS            decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	QU_ITM_SLD           decimal(3,0)  NOT NULL 
		 DEFAULT  0,
	QU_BLK_ITM_SLD       decimal(3,0)  NOT NULL 
		 DEFAULT  0,
	MO_COGS              decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_NET_MRGN          decimal(16,5)  NOT NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_STRD_SMRY_CT_SLSRTN
	ADD  PRIMARY KEY  CLUSTERED (ID_CT ASC,ID_TRN ASC,ID_BSN_UN ASC,DC_DY_BSN ASC,ID_CHNL ASC)
go



CREATE TABLE DW3_STRD_SMRY_CT_TNDR
( 
	ID_CT                integer  NOT NULL ,
	DC_DY_BSN            date  NOT NULL ,
	ID_BSN_UN            char(32)  NOT NULL ,
	ID_CHNL              integer  NOT NULL ,
	ID_TRN               char(32)  NOT NULL ,
	TY_TND               varchar(20)  NOT NULL ,
	MO_TRN_ALL_TNDR_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	CASH_TNDR_LN_ITM_COUNT integer  NULL ,
	CHECK_TNDR_LN_ITM_COUNT integer  NULL ,
	CRDB_TNDR_LN_ITM_COUNT integer  NULL ,
	CPN_TNDR_LN_ITM_COUNT integer  NULL ,
	STRD_VL_LN_ITM_COUNT integer  NULL ,
	CT_ACT_LN_ITM_COUNT  integer  NULL ,
	TRADEIN_LN_ITM_COUNT integer  NULL ,
	EBT_LN_ITM_COUNT     integer  NULL ,
	MO_CSH_TRN_APPLD     decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_CHK_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_DBCR_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_CPN_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_GF_CF_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_CTAC_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_TRADEIN_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0,
	MO_EBT_TRN_TOT_APPLD decimal(16,5)  NOT NULL 
		 DEFAULT  0
)
go



ALTER TABLE DW3_STRD_SMRY_CT_TNDR
	ADD  PRIMARY KEY  CLUSTERED (ID_CT ASC,DC_DY_BSN ASC,ID_BSN_UN ASC,ID_CHNL ASC,ID_TRN ASC,TY_TND ASC)
go
--------------------------------------------------------------------------------
-- S A M P L E   S T O R E D   S U M M A R Y   T A B L E S                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Build a stored summary table to use for the SALES and ITEM related sample  --
-- customer performance measure queries.  This is an intermediate rowset      --
-- that is used as input to the queries used by differen performance measures --
--------------------------------------------------------------------------------
-- Create VW_DW3_CT_SLSRTN_STRD_SMRY - Customer Sale/Return Stored Summary    --
-- View                                                                       --
--------------------------------------------------------------------------------
--drop view VW_DW3_CT_SLSRTN_STRD_SMRY;
create view VW_DW3_CT_SLSRTN_STRD_SMRY as
with SLSRTN as
    (
    ----------------------------------------------------------------------------
    -- This subquery assembles and calculates LINE ITEM LEVEL net values to   --
    -- make the summarization mainline query simpler.  This also helps in     --
    -- debugging.                                                             --
    ----------------------------------------------------------------------------
         select
             ID_CT                                         -- Customer ID
            ,DC_DY_BSN                                     -- Business Day Date
            ,ID_BSN_UN                                     -- Business Unit (store)
            ,ID_CHNL                                       -- Channel
            ,ID_TRN                                        -- Transaction
            ,IC_LN_ITM                                     -- Transaction Line Item
            ,MO_EXTND                                      -- Extended actual amount
            --------------------------------------------------------------------
            -- Logic here handles bulk items and items sold in retail selling --
            -- units.  They have different ways handling quantity sold.  The  --
            -- retail selling unit type items have to handle a "2 for" or     --
            -- "3 for" unit price that applies to sets of retail selling      --
            -- units.  This carries over to the calculation of net margin     --
            --------------------------------------------------------------------
            ,QU_UN 
            ,QU_ITM_LM_RTN_SLS
                                                             
            ,case
                when TY_ITM_STK = 'BULK'  and QU_UN > 0
                    then CP_INV * QU_UN                       -- Bulk item extended cost
                else
                    (CP_INV/UN_INV_UPRQY) * QU_ITM_LM_RTN_SLS  -- Retail Selling Unit ext cost
             end as MO_CST_INV_EXTND                           -- Inventory Cost
            ,case
                when TY_ITM_STK = 'BULK' and QU_UN > 0
                    then MO_EXTND - (CP_INV * QU_UN)
                else 
                    MO_EXTND - ((CP_INV/UN_INV_UPRQY) * QU_ITM_LM_RTN_SLS)
             end as NET_MRGN                                   -- Line item net margin
             
         from
             DW3_FACT_SALE_RTN_BEHAVIOR
             join DW3_DIM_ITM
             on DW3_FACT_SALE_RTN_BEHAVIOR.ID_ITM = DW3_DIM_ITM.ID_ITM
         -----------------------------------------------------------------------
         -- For analytic purposes we're filtering out voided, canceled and    --
         -- training transactions.  If this query were being used for audit   --
         -- purposes, these should be included.                               --
         ----------------------------------------------------------------------- 
         where
              FL_CNCL = 0          -- Include only transactions that are NOT canceled
              AND FL_VD = 0        -- Include only transactioins that are NOT voided
              AND FL_SPN = 0       -- Include only transactions that are NOT suspended
              AND FL_TRG_TRN = 0   -- Include only transactions that are NOT training 
                                   -- transaction   
    )
--------------------------------------------------------------------------------
-- Summarize line items to CUSTOMER TRANSACTION level                         --
--------------------------------------------------------------------------------
select
     SLSRTN.ID_CT                                         -- Customer
    ,SLSRTN.DC_DY_BSN                                     -- Business Day Date
    ,SLSRTN.ID_BSN_UN                                     -- Business Unit (store)
    ,SLSRTN.ID_CHNL                                       -- Channel
    ,SLSRTN.ID_TRN                                        -- Transaction
    ,COUNT(SLSRTN.IC_LN_ITM) as QU_LN_ITM                 -- Transaction Line Item Count
    ,SUM(SLSRTN.MO_EXTND)    as MO_NT_SLS                 -- Transaction Net Sales
    ,SUM(SLSRTN.QU_ITM_LM_RTN_SLS) as QU_ITM_SLD          -- Quantity of items sold
                                                          -- (retail selling units)
    ,SUM(SLSRTN.QU_UN) as QU_BLK_ITM_SLD                  -- BULK item qty sold
    ,SUM(SLSRTN.MO_CST_INV_EXTND) as MO_COGS              -- Total INVENTORY COGS
    ,SUM(SLSRTN.NET_MRGN) as MO_NET_MRGN                  -- Net Margin
from
    SLSRTN 
group by   
     SLSRTN.ID_CT                                         -- Customer
    ,SLSRTN.DC_DY_BSN                                     -- Business Day Date
    ,SLSRTN.ID_BSN_UN                                     -- Business Unit (store)
    ,SLSRTN.ID_CHNL                                       -- Channel
    ,SLSRTN.ID_TRN                                        -- Transaction
;
--------------------------------------------------------------------------------
-- End VW_DW3_CT_SLSRTN_STRD_SMRY - Customer Sale/Return Stored Summary View  --
--------------------------------------------------------------------------------
go



--------------------------------------------------------------------------------
-- Build a stored summary table to use for the TENDER related sample customer --
-- performance measures                                                       --
--------------------------------------------------------------------------------
-- Create View VW_DW3_CT_TNDR_STRD_SRMY - Customer Tender Stored Summary      --
-- View                                                                       --
--------------------------------------------------------------------------------
--drop view VW_DW3_CT_TNDR_STRD_SMRY;
create view VW_DW3_CT_TNDR_STRD_SMRY as
with TNDR as
    (
        select
             ID_CT
            ,DC_DY_BSN
            ,ID_BSN_UN
            ,ID_CHNL
            ,ID_TRN
            ,TY_TND
            ,MO_TRN_AMT
            --------------------------------------------------------------------
            -- Case statements set count indicators for all of the different  --
            -- kinds of tenders so we can analyze customer tender usage       --
            -- within and across transactions.                                --
            --------------------------------------------------------------------
            ,case
                 when TY_TND = 'CASH' then 1
                 else 0
             end as IND_CASH
            ,case
                 when TY_TND in ('CHEQUE','CHECK') then 1
                 else 0
             end as IND_CHECK
            ,case
                 when TY_TND in ('CREDIT','DEBIT') then 1
                 else 0
             end as IND_CRDB
            ,case
                 when TY_TND = 'COUPON' then 1
                 else 0
             end as IND_COUPON
            ,case
                 when TY_TND = 'STORED_VALUE' then 1
                 else 0
             end as IND_STORED_VALUE
            ,case
                 when TY_TND = 'CUST_ACCT' then 1
                 else 0
             end as IND_CUST_ACCT
            ,case
                 when TY_TND = 'TRADEIN' then 1
                 else 0
             end as IND_TRADEIN
            ,case
                 when TY_TND = 'EBT' then 1
                 else 0
             end as IND_EBT
           ---------------------------------------------------------------------
           -- Case statements to standardize handling differet credit/debit   --
           -- card issues and co branding for subsequent analysis             --
           ---------------------------------------------------------------------
           ,case
               when TY_TND in ('CREDIT','DEBIT') then
                   CRDB_TY_CRD
               else 'NON_CRDB_TENDER'
            end as CRDB_TY_CRD
           ,case
               when TY_TND in ('CREDIT','DEBIT') then
                   CRDB_ID_TND_MD_BRN
               else 'NON_CRDB_TENDER'
            end as CRDB_ID_TND_MD_BRN
          ,CD_CNY_ISO_4217_LCL       -- Retailers local currency 
          ,CD_CNY_ISO_4217_TND       -- The currency tendered in this line item
          ,case
              when CD_CNY_ISO_4217_LCL <> CD_CNY_ISO_4217_TND then 1
              else 0
           end as CNY_CNV_IND        -- use to count currency conversions for analysis
           ---------------------------------------------------------------------
           -- Tender monetary values split out by tender type for rollup      --
           -- In this sample we are omitting the possible special handling    --
           -- fees charged by a retailer for converting foreign currency      --
           -- taken as payment and foreign currency returned as change to a   --
           -- customer.  We include only the local currency value, exchange   --
           -- rate and foreign currency value.                                --
           ---------------------------------------------------------------------
          ,CSH_MO_ITM_LN_TND  -- Amount of cash tendered by the customer
          ,CSH_MO_TRN_AMT     -- Amount of cash tender applied to settle trans
          ,CSH_MO_FRG_CY      -- Foreign currency amount tender applier
          ,CSH_MO_RTE_EXC     -- Cash exchange rate (NON-ADDITIVE fact)
          ----------------------------------------------------------------------
          -- Change returned to customer as part of settlement where tender   --
          -- value of payment exceeds the total sale value.                   --
          ----------------------------------------------------------------------
          ,CHG_MO_ITM_LN_TND  -- Change amount returned to customer (in retail local currency) 
          ,CHG_MO_FRG_CY      -- Change amount returned to customer in foreign currency
          ,CHG_MO_RTE_EXC     -- Change exchange rate
          ----------------------------------------------------------------------
          -- In this sample, we are assuming that checks will be denominated  --
          -- in the retailer's local currency                                 --
          ----------------------------------------------------------------------
          ,CHK_MO_ITM_LN_TND  -- Check amount tendered by the customer
          ,CHK_MO_TRN_AMT     -- Amount of check tender applied to settle transaction
          ----------------------------------------------------------------------
          ,CRDB_MO_ITM_LN_TND -- Credit Debit card amount tendered
          ,CRDB_MO_TRN_AMT    -- Credit Debit card amount applied to transaction
          ----------------------------------------------------------------------
          ,CPN_MO_ITM_LN_TND  -- Coupon amount tendered
          ,CPN_MO_TRN_AMT     -- Coupon amount applied to transaction
          ----------------------------------------------------------------------
          ,GF_CF_MO_ITM_LN_TND -- Gift Cert (stored value) amount tendered
          ,GF_CF_MO_TRN_AMT    -- Gift Cert amount applied to transaction
          ----------------------------------------------------------------------
          ,CTAC_MO_ITM_LN_TND  -- Total Customer Account charged (A/R debit)
          ,CTAC_MO_TRN_AMT     -- Customer Account charge applied to transaction
          ----------------------------------------------------------------------
          ,TRADEIN_MO_ITM_LN_TND -- Tradein Total amount tendered
          ,TRADEIN_MO_TRN_AMT    -- Tradein amount applied to transaction
          ----------------------------------------------------------------------
          ,EBT_MO_ITM_LN_TND     -- EBT total amount tendered
          ,EBT_MO_TRN_AMT        -- EBT amount applied to transaction
          ----------------------------------------------------------------------

        from
            DW3_FACT_TENDER_BEHAVIOR
        where
              FL_CNCL = 0          -- Include only transactions that are NOT canceled
              AND FL_VD = 0        -- Include only transactioins that are NOT voided
              AND FL_SPN = 0       -- Include only transactions that are NOT suspended
              AND FL_TRG_TRN = 0   -- Include only transactions that are NOT training 
                                   -- transaction   
    )
--------------------------------------------------------------------------------
-- Note we will aggregate ALL tender line items into a single row that counts --
-- line items by tender type and returns the tender value actuall assigned to --
-- the transaction.  This is aimed at supporting the spreadsheet tender       --
-- related performance measures.                                              --
--------------------------------------------------------------------------------
select
     TNDR.ID_CT
    ,TNDR.DC_DY_BSN
    ,TNDR.ID_BSN_UN
    ,TNDR.ID_CHNL
    ,TNDR.ID_TRN
    ,TNDR.TY_TND
    ----------------------------------------------------------------------------
    -- In this sample ALL tender amounts are in the retailer's local currency --
    -- since the performance measures were silent on foreign currncy.         --
    ----------------------------------------------------------------------------
    ,SUM(TNDR.MO_TRN_AMT) AS MO_TRN_ALL_TNDR_APPLD
    ,SUM(TNDR.IND_CASH) AS CASH_TNDR_LN_ITM_COUNT
    ,SUM(TNDR.IND_CHECK) AS CHECK_TNDR_LN_ITM_COUNT
    ,SUM(TNDR.IND_CRDB) AS CRDB_TNDR_LN_ITM_COUNT
    ,SUM(TNDR.IND_COUPON) AS CPN_TNDR_LN_ITM_COUNT
    ,SUM(TNDR.IND_STORED_VALUE) AS STRD_VL_LN_ITM_COUNT
    ,SUM(TNDR.IND_CUST_ACCT) AS CT_ACT_LN_ITM_COUNT
    ,SUM(TNDR.IND_TRADEIN) AS TRADEIN_LN_ITM_COUNT
    ,SUM(TNDR.IND_EBT) AS EBT_LN_ITM_COUNT
    ,SUM(TNDR.CSH_MO_TRN_AMT) AS MO_TRN_TOT_APPLD
    ,SUM(TNDR.CHK_MO_TRN_AMT) AS MO_CHK_TRN_TOT_APPLD
    ,SUM(TNDR.CRDB_MO_TRN_AMT) AS MO_DBCR_TRN_TOT_APPLD
    ,SUM(TNDR.CPN_MO_TRN_AMT) AS MO_CPN_TRN_TOT_APPLD
    ,SUM(TNDR.GF_CF_MO_TRN_AMT) AS MO_GF_CF_TRN_TOT_APPLD
    ,SUM(TNDR.CTAC_MO_TRN_AMT) AS MO_CTAC_TRN_TOT_APPLD
    ,SUM(TNDR.TRADEIN_MO_TRN_AMT) AS MO_TRADEIN_TRN_TOT_APPLD
    ,SUM(TNDR.EBT_MO_TRN_AMT) AS MO_EBT_TRN_TOT_APPLD
from
     TNDR    
group by
     TNDR.ID_CT
    ,TNDR.DC_DY_BSN
    ,TNDR.ID_BSN_UN
    ,TNDR.ID_CHNL
    ,TNDR.ID_TRN
    ,TNDR.TY_TND
;
--------------------------------------------------------------------------------
-- END View VW_DW3_CT_TNDR_ST_SRMY - Customer Tender Stored Summary Table     --
--------------------------------------------------------------------------------

go



--------------------------------------------------------------------------------
-- Inventory Velocity Sample Query                                            --
--------------------------------------------------------------------------------
-- This sample query summarizes inventory movement in to and out of a         --
-- BusinessUnit for a reporting period to present an aggregate inventory      --
-- velocity measure. This is the kind of metric that might show up on a       --
-- store manager's dashboard.  It provides an indicator of inventory          --
-- movement.                                                                  --
--                                                                            --
-- This sample only considers item movement in UNITS.  This is to simplify    --
-- the details for this illustration.  Typically, retailers will look at      --
-- inventory velocity in UNITS and MONETARY value.                            --
--------------------------------------------------------------------------------
--drop view VW_DW3_BSN_RP_INV_VLCTY;
create view VW_DW3_BSN_RP_INV_VLCTY as
with INVTY_DTL as
    (
        select
            --------------------------------------------------------------------
            -- ARTS most granular level of inventory tracking is by item,     --
            -- business unit, location inside a business unit, inventory      --
            -- state (i.e. damaged, reserved, available for sale) and revenue --
            -- cost center. This fact data consists of beginning and ending   --
            -- unit count balances for a REPORTING PERIOD and cumulative      --
            -- counts for different inventory actions (receipts, sales, etc.).--                                       --
            --------------------------------------------------------------------
             DW3_FACT_INVENTORY.ID_ITM         -- Item ID (SKU)
            ,DW3_FACT_INVENTORY.ID_BSN_UN      -- Business Unit
            ,DW3_FACT_INVENTORY.ID_LCN         -- Location inside Business Unit
            ,DW3_FACT_INVENTORY.ID_ST_INV      -- Inventory State
            ,DW3_FACT_INVENTORY.ID_CTR_RVN_CST -- Revenue Cost Center
            ,DW3_FACT_INVENTORY.ID_PRD_RP      -- Reporting Period
            --------------------------------------------------------------------
            -- Reporting period summary data in our InventoryFact table       --
            --------------------------------------------------------------------
            ,DW3_FACT_INVENTORY.QU_BGN         -- Beginning unit count balance
            ,DW3_FACT_INVENTORY.QU_RCV         -- Cumulative Quantity received
            ,DW3_FACT_INVENTORY.QU_TSF_IN      -- Cumulative Transfer In
            ,DW3_FACT_INVENTORY.QU_TSF_OT      -- Cumulative Transfer Out
            ,DW3_FACT_INVENTORY.QU_ADJT        -- Cumulative Adjustment 
            ,DW3_FACT_INVENTORY.QU_RTN         -- CUmulative Customer Returns
            ,DW3_FACT_INVENTORY.QU_SLS         -- Cumulative Sales
            ,DW3_FACT_INVENTORY.QU_RTV         -- Cumulative Return to Vendor
            ,DW3_FACT_INVENTORY.QU_END         -- Ending unit count balance
            -------------------------------------------------------------------
            -- Calculate non-additive facts at most granular level           --
            -------------------------------------------------------------------
            ,(DW3_FACT_INVENTORY.QU_BGN +
              DW3_FACT_INVENTORY.QU_END)/2 
              as QU_AVG_INVTY                  -- Average Inventory for Reporting Period
                                               -- which is a NON-ADDITIVE fact
            ,DW3_FACT_INVENTORY.QU_SLS/        
             ((DW3_FACT_INVENTORY.QU_BGN +
              DW3_FACT_INVENTORY.QU_END)/2)
              as QU_TRNOVR_INVTY               -- Inventory Turnover 
                                               -- which is a NON-ADDITIVE fact

        from
            DW3_FACT_INVENTORY
    )    
--------------------------------------------------------------------------------
-- Summarization to business unit level using the INVTY_DTL subquery which    --
-- provides the most granular level of detail avaible from the InventoryFact  --
-- table. The inventory balances and summary counts are additive fact in this --
-- sample because they are summed along a NON-reporting period dimension      --
-- (business unit).                                                           --
--------------------------------------------------------------------------------
select
     INVTY_DTL.ID_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.NM_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.TY_BSN_UN
    ,INVTY_DTL.ID_PRD_RP
    ,SUM(INVTY_DTL.QU_BGN)    as QU_BGN
    ,SUM(INVTY_DTL.QU_RCV)    as QU_RCV
    ,SUM(INVTY_DTL.QU_TSF_IN) as QU_TSF_IN
    ,SUM(INVTY_DTL.QU_TSF_OT) as QU_TSF_OT
    ,SUM(INVTY_DTL.QU_ADJT)   as QU_ADJT
    ,SUM(INVTY_DTL.QU_RTN)    as QU_RTN
    ,SUM(INVTY_DTL.QU_SLS)    as QU_SLS
    ,SUM(INVTY_DTL.QU_RTV)    as QU_RTV
    ,SUM(INVTY_DTL.QU_END)    as QU_END
    ----------------------------------------------------------------------------
    -- Recalculate average inventory and inventory turnover for BUSINESS      --
    -- UNIT since the detailed calculations are NON-ADDITIVE facts. We use    --
    -- business unit summary facts to do this calculation.                    --
    ----------------------------------------------------------------------------
    ,(SUM(INVTY_DTL.QU_BGN) + SUM(INVTY_DTL.QU_END))/2 as QU_BSN_UN_AVG_INVTY
    ,SUM(INVTY_DTL.QU_SLS) /
     ((SUM(INVTY_DTL.QU_BGN) + SUM(INVTY_DTL.QU_END))/2)as QU_BSN_UN_TRNOVR_INVTY
    
from
    INVTY_DTL
    join DW3_DIM_BUSINESS_UNIT
    on INVTY_DTL.ID_BSN_UN =  DW3_DIM_BUSINESS_UNIT.ID_BSN_UN
group by
     INVTY_DTL.ID_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.NM_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.TY_BSN_UN
    ,INVTY_DTL.ID_PRD_RP
;
--------------------------------------------------------------------------------
-- END Inventory Velocity Sample Query                                        --
--------------------------------------------------------------------------------

go



--------------------------------------------------------------------------------
-- Inventory Velocity Units and Cost Sample Query by Business Unit Reporting  --
-- Period                                                                     --
--------------------------------------------------------------------------------
-- This sample view summarizes inventory movement in to and out of a          --
-- BusinessUnit to present an aggregate inventory velocity measure. This is   --
-- the kind of metric that might show up on a store manager's dashboard.  It  --
-- provides an indicator of inventory movement.  It tells the manager to look -- 
-- deeper if inventory movement is below or above an expected value. To look  --
-- deeper additional, more detailed summary query drilling down to the        --
-- individual item level.                                                     --
--                                                                            --
--------------------------------------------------------------------------------
--drop view VW_DW3_BSN_RP_INV_VLCTY_CST;
create view VW_DW3_BSN_RP_INV_VLCTY_CST as
with INVTY_DTL as 
    (
        select
            --------------------------------------------------------------------
            -- ARTS most granular level of inventory tracking is by item,     --
            -- business unit, location inside a business unit, inventory      --
            -- state (i.e. damaged, reserved, available for sale) and revenue --
            -- cost center.  This fact data consists of beginning and ending  --
            -- unit count balances for a REPORTING PERIOD and cumulative      --
            -- counts for different inventory actions (receipts, sales, etc.).--
            --------------------------------------------------------------------
             DW3_FACT_INVENTORY.ID_ITM         -- Item ID (SKU)
            ,DW3_FACT_INVENTORY.ID_BSN_UN      -- Business Unit
            ,DW3_FACT_INVENTORY.ID_LCN         -- Location inside Business Unit
            ,DW3_FACT_INVENTORY.ID_ST_INV      -- Inventory State
            ,DW3_FACT_INVENTORY.ID_CTR_RVN_CST -- Revenue Cost Center
            ,DW3_FACT_INVENTORY.ID_PRD_RP      -- Reporting Period
            --------------------------------------------------------------------
            -- Reporting period summary data in our InventoryFact table       --
            --------------------------------------------------------------------
            ,DW3_FACT_INVENTORY.QU_BGN         -- Beginning unit count balance
            ,DW3_FACT_INVENTORY.QU_RCV         -- Cumulative Quantity received
            ,DW3_FACT_INVENTORY.QU_TSF_IN      -- Cumulative Transfer In
            ,DW3_FACT_INVENTORY.QU_TSF_OT      -- Cumulative Transfer Out
            ,DW3_FACT_INVENTORY.QU_ADJT        -- Cumulative Adjustment 
            ,DW3_FACT_INVENTORY.QU_RTN         -- CUmulative Customer Returns
            ,DW3_FACT_INVENTORY.QU_SLS         -- Cumulative Sales
            ,DW3_FACT_INVENTORY.QU_RTV         -- Cumulative Return to Vendor
            ,DW3_FACT_INVENTORY.QU_END         -- Ending unit count balance
            --------------------------------------------------------------------
            -- Reporting Period Inventory Cost of inventory moved             --
            --------------------------------------------------------------------
            ,DW3_FACT_INVENTORY.QU_BGN *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_BGN
                as CP_BGN                      -- Beginning Inventory AT cost
            ,DW3_FACT_INVENTORY.TC_RCV_CM      -- Total cost of receipts based on
                                               -- actual receiving item costs 
            --------------------------------------------------------------------
            -- The following inventory movement costs use the reporting       --
            -- period ending average unit cost  			                  --
            --------------------------------------------------------------------             
            ,DW3_FACT_INVENTORY.QU_TSF_IN *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_TSF_IN                   -- Transfer in cost 

            ,DW3_FACT_INVENTORY.QU_TSF_OT *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_TSF_OT                   -- Transfer out cost

            ,DW3_FACT_INVENTORY.QU_ADJT *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_ADJT                     -- Adjustment cost

            ,DW3_FACT_INVENTORY.QU_RTN *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_RTN                      -- Customer return cost
   
            ,DW3_FACT_INVENTORY.QU_SLS *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_SLS                      -- Sales cost (COGS)

            ,DW3_FACT_INVENTORY.QU_RTV *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_RTV                      -- Return to vendor cost

            ,DW3_FACT_INVENTORY.QU_END *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END
                as CP_END                      -- Ending inventory AT cost
 
            --------------------------------------------------------------------
            -- Calculate non-additive UNIT facts at most granular level       --
            --------------------------------------------------------------------
            ,(DW3_FACT_INVENTORY.QU_BGN +
              DW3_FACT_INVENTORY.QU_END)/2 
              as QU_AVG_INVTY           -- Average Inventory UNITS for Reporting 
                                        -- Period which is a NON-ADDITIVE fact
            ,DW3_FACT_INVENTORY.QU_SLS/        
             ((DW3_FACT_INVENTORY.QU_BGN +
              DW3_FACT_INVENTORY.QU_END)/2)
              as QU_TRNOVR_INVTY        -- Inventory Turnover UNITS
                                        -- which is a NON-ADDITIVE fact
            --------------------------------------------------------------------
            -- Calculate non-additive COST facts at most granular level       --
            -- NOTE: The ODM sums the receipts, transfers, sales and other    --
            -- actions into a reporting period ending balance (QU_END) so     --
            -- we use that in this query to calculate ending inventory cost.  --
            --------------------------------------------------------------------
            ,((DW3_FACT_INVENTORY.QU_BGN * 
                DW3_FACT_INVENTORY.CP_UN_AV_WT_BGN) +
                (DW3_FACT_INVENTORY.QU_END * 
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END))/ 2
                as CP_AVG_INVTY        -- Average Inventory COST for Reporting
                                       -- Period which is a NON-ADDITIVE fact.
            ,(DW3_FACT_INVENTORY.QU_SLS *
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END) /
                (((DW3_FACT_INVENTORY.QU_BGN * 
                DW3_FACT_INVENTORY.CP_UN_AV_WT_BGN) +
                (DW3_FACT_INVENTORY.QU_END * 
                DW3_FACT_INVENTORY.CP_UN_AV_WT_END))/ 2)
                as CP_TRNOVR_INVTY    -- Inventory Turnover COST
                                      -- which is a NON-ADDITIVE fact
        from
            DW3_FACT_INVENTORY
    )    
--------------------------------------------------------------------------------
-- Summarization to business unit level using the INVTY_DTL subquery which    --
-- provides the most granular level of detail avaible from the InventoryFact  --
-- table. The inventory balances and summary counts are additive fact in this --
-- sample because they are summed along a NON-reporting period dimension      --
-- (business unit)                                                            --
--------------------------------------------------------------------------------
select
     INVTY_DTL.ID_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.NM_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.TY_BSN_UN
    ,INVTY_DTL.ID_PRD_RP
    ----------------------------------------------------------------------------
    -- Unit summary (additive)                                                --
    ----------------------------------------------------------------------------
    ,SUM(INVTY_DTL.QU_BGN)     as QU_BGN     -- Beginning Quantity
    ,SUM(INVTY_DTL.QU_RCV)     as QU_RCV     -- Received Quantity
    ,SUM(INVTY_DTL.QU_TSF_IN)  as QU_TSF_IN  -- Transferred In Quantity
    ,SUM(INVTY_DTL.QU_TSF_OT)  as QU_TSF_OT  -- Transferred Out Quantity
    ,SUM(INVTY_DTL.QU_ADJT)    as QU_ADJT    -- Adjusted Quantity
    ,SUM(INVTY_DTL.QU_RTN)     as QU_RTN     -- Customer Return Quantity
    ,SUM(INVTY_DTL.QU_SLS)     as QU_SLS     -- Sold Quantity
    ,SUM(INVTY_DTL.QU_RTV)     as QU_RTV     -- Return to Vendor Quantity
    ,SUM(INVTY_DTL.QU_END)     as QU_END     -- Ending Quantity
    ----------------------------------------------------------------------------
    -- Cost summary (additive)                                                --
    ----------------------------------------------------------------------------
    ,SUM(INVTY_DTL.CP_BGN)     as CP_BGN     -- Beginning cost
    ,SUM(INVTY_DTL.TC_RCV_CM)  as TC_RCV_CM  -- Received cost
    ,SUM(INVTY_DTL.CP_TSF_IN)  as CP_TSF_IN  -- Transfer In Cost
    ,SUM(INVTY_DTL.CP_TSF_OT)  as CP_TFS_OUT -- Transfer Out Cost
    ,SUM(INVTY_DTL.CP_ADJT)    as CP_ADJT    -- Adjustment Cost
    ,SUM(INVTY_DTL.CP_RTN)     as CP_RTN     -- Customer Return Cost Value
    ,SUM(INVTY_DTL.CP_SLS)     as CP_SLS     -- Cost of goods sold
    ,SUM(INVTY_DTL.CP_RTV)     as CP_RTV     -- Return to vendor cost
    ,SUM(INVTY_DTL.CP_END)     as CP_END     -- Ending inventory cost
    ----------------------------------------------------------------------------
    -- Recalculate average inventory and inventory turnover for BUSINESS      --
    -- UNIT reporting period since the detailed calculations are NON-ADDITIVE --
    -- facts. We use business unit level summary facts to do this             --
    --calculation.                                                            --
    ----------------------------------------------------------------------------
    ,(SUM(INVTY_DTL.QU_BGN) + SUM(INVTY_DTL.QU_END))/2 as QU_BSN_UN_AVG_INVTY
    ,SUM(INVTY_DTL.QU_SLS) /
     ((SUM(INVTY_DTL.QU_BGN) + SUM(INVTY_DTL.QU_END))/2)as QU_BSN_UN_TRNOVR_INVTY
     ---------------------------------------------------------------------------
     -- Recalculate average inventory COST and inventory turnover for         --
     -- BUSINESS UNIT reporting period since the detailed calculations are    --
     -- NON-ADDITIVE FACTS.                                                   --
     ---------------------------------------------------------------------------
    ,(SUM(INVTY_DTL.CP_BGN) + SUM(INVTY_DTL.CP_END)) / 2 as CP_BSN_UN_AVG_INVTY
    ,SUM(INVTY_DTL.CP_SLS)/
        ((SUM(INVTY_DTL.CP_BGN) + SUM(INVTY_DTL.CP_END)) / 2) as CP_BSN_UN_TRNOVR_INVTY
from
    INVTY_DTL
    join DW3_DIM_BUSINESS_UNIT
    on INVTY_DTL.ID_BSN_UN =  DW3_DIM_BUSINESS_UNIT.ID_BSN_UN
group by
     INVTY_DTL.ID_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.NM_BSN_UN
    ,DW3_DIM_BUSINESS_UNIT.TY_BSN_UN
    ,INVTY_DTL.ID_PRD_RP
;
--------------------------------------------------------------------------------
-- END Inventory Velocity using COST Sample Query                             --
--------------------------------------------------------------------------------
go



--------------------------------------------------------------------------------
-- STEP 1: Create View VW_DW3_BSN_UN_QRTLY_SLS                                --
--------------------------------------------------------------------------------
-- Business Unit Quarterly Sales View - Generalized Quarter Roll up of Net    --
-- Sales and Net Margin by business unit.  Same pattern can be used for any   --
-- NRF 4-5-4 period.                                                          --
--------------------------------------------------------------------------------
-- drop view VW_DW3_BSN_UN_QRTLY_SLS;
create view VW_DW3_BSN_UN_QRTLY_SLS AS 
with ALL_PRD_NET_SLS as
    (
        Select
             DW3_STRD_SMRY_CT_SLSRTN.ID_BSN_UN
            ,DW3_STRD_SMRY_CT_SLSRTN.DC_DY_BSN
            ,DW3_STRD_SMRY_CT_SLSRTN.MO_NT_SLS
            ,DW3_STRD_SMRY_CT_SLSRTN.MO_NET_MRGN
            ,dbo.FN_REVSPLIT(DW3_DIM_CA_HIER.CLD_PRD_LVL_NM_PTH,'|') as CLD_PRD_LVL_NM_PTH
            ,dbo.FN_REVSPLIT(DW3_DIM_CA_HIER.CLD_PRD_NM_PTH,'|') as CLD_PRD_NM_PTH

        FROM
            DW3_STRD_SMRY_CT_SLSRTN
            join DW3_DIM_CA_HIER
            on DW3_STRD_SMRY_CT_SLSRTN.DC_DY_BSN = DW3_DIM_CA_HIER.DC_DY_BSN
            and DW3_DIM_CA_HIER.NM_CLD = 'NRF 4-5-4 Retail Calendar'
    )

select
     ALL_PRD_NET_SLS.ID_BSN_UN
    ,dbo.FN_RP_CP_EXTR
        (
             ALL_PRD_NET_SLS.CLD_PRD_LVL_NM_PTH
            ,ALL_PRD_NET_SLS.CLD_PRD_NM_PTH
            ,'|'
            ,'QUARTER'
        ) as NRF_454_YR_QTR
    ,sum(ALL_PRD_NET_SLS.MO_NT_SLS) MO_BSN_UN_QTR_NET_SLS
    ,sum(ALL_PRD_NET_SLS.MO_NET_MRGN) MO_BSN_UN_QTR_NET_MRGN
from
    ALL_PRD_NET_SLS    
group by
     ALL_PRD_NET_SLS.ID_BSN_UN
    ,dbo.FN_RP_CP_EXTR
        (
             ALL_PRD_NET_SLS.CLD_PRD_LVL_NM_PTH
            ,ALL_PRD_NET_SLS.CLD_PRD_NM_PTH
            ,'|'
            ,'QUARTER'
        ) 
;           
--------------------------------------------------------------------------------
-- End View VW_DW3_BSN_UN_QRTLY_SLS                                           --
-- END Business Unit Quarterly Sales View - Generalized Quarter Roll up of Net--
-- Sales and Net Margin by business unit.  Same pattern can be used for any   --
-- NRF 4-5-4 period.                                                          --
--------------------------------------------------------------------------------

go




ALTER TABLE CO_CD_RSN
	ADD  FOREIGN KEY (CD_RSN_GRP) REFERENCES CO_CD_RSN_GRP(CD_RSN_GRP)
		ON DELETE SET NULL
		ON UPDATE SET NULL
go




ALTER TABLE CO_CVN_UOM
	ADD  FOREIGN KEY (CD_CVN_UOM_TO) REFERENCES CO_UOM(CD_UOM)
go




ALTER TABLE CO_CVN_UOM
	ADD  FOREIGN KEY (CD_CVN_UOM_FM) REFERENCES CO_UOM(CD_UOM)
go




ALTER TABLE DW3_DIM_APR
	ADD  FOREIGN KEY (ID_ITM) REFERENCES DW3_DIM_ITM(ID_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_BSN_UN_GEO_HIER
	ADD  FOREIGN KEY (ID_BSN_UN) REFERENCES DW3_DIM_BUSINESS_UNIT(ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_BSN_UN_GEO_HIER
	ADD  FOREIGN KEY (ID_GEO_LCN,ID_GEO_SGMT_HRC) REFERENCES DW3_DIM_GEO_HRC_SGMT(ID_GEO_LCN,ID_GEO_SGMT_HRC)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_BSNGP
	ADD  FOREIGN KEY (ID_BSN_UN) REFERENCES DW3_DIM_BUSINESS_UNIT(ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_CT
	ADD  FOREIGN KEY (ID_CT_HSHLD) REFERENCES DW3_DIM_HSHLD(ID_HSHLD)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_CT_GEO_SGMT
	ADD  FOREIGN KEY (ID_CT) REFERENCES DW3_DIM_CT(ID_CT)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_CT_GEO_SGMT
	ADD  FOREIGN KEY (ID_GEO_LCN,ID_GEO_SGMT_HRC) REFERENCES DW3_DIM_GEO_HRC_SGMT(ID_GEO_LCN,ID_GEO_SGMT_HRC)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_CT_LYLTY
	ADD  FOREIGN KEY (ID_CT) REFERENCES DW3_DIM_CT(ID_CT)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_HSHLD_CNCT
	ADD  FOREIGN KEY (ID_HSHLD) REFERENCES DW3_DIM_HSHLD(ID_HSHLD)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_INVENTORY_LOCATION
	ADD  FOREIGN KEY (ID_BSN_UN) REFERENCES DW3_DIM_BUSINESS_UNIT(ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ITM
	ADD  FOREIGN KEY (CD_UOM) REFERENCES CO_UOM(CD_UOM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_MDSE_HIER
	ADD  FOREIGN KEY (ID_ITM) REFERENCES DW3_DIM_ITM(ID_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_CA
	ADD  FOREIGN KEY (ID_TRN,IC_LN_ITM) REFERENCES DW3_FACT_TENDER_BEHAVIOR(ID_TRN,IC_LN_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_CA
	ADD  FOREIGN KEY (ID_TRN,IC_LN_ITM) REFERENCES DW3_FACT_SALE_RTN_BEHAVIOR(ID_TRN,IC_LN_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_CA
	ADD  FOREIGN KEY (ID_CLD,DC_DY_BSN) REFERENCES DW3_DIM_CA_HIER(ID_CLD,DC_DY_BSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_CA
	ADD  FOREIGN KEY (ID_TRN,IC_LN_ITM) REFERENCES DW3_FACT_CT_LYLTY_BEHAVIOR(ID_TRN,IC_LN_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_RP
	ADD  FOREIGN KEY (ID_PRD_RP,DC_DY_BSN) REFERENCES DW3_DIM_CA_PRD_RP(ID_PRD_RP,DC_DY_BSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_RP
	ADD  FOREIGN KEY (ID_TRN,IC_LN_ITM) REFERENCES DW3_FACT_TENDER_BEHAVIOR(ID_TRN,IC_LN_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_RP
	ADD  FOREIGN KEY (ID_TRN,IC_LN_ITM) REFERENCES DW3_FACT_SALE_RTN_BEHAVIOR(ID_TRN,IC_LN_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_DIM_ST_ASCTN_RTL_TRN_RP
	ADD  FOREIGN KEY (ID_TRN,IC_LN_ITM) REFERENCES DW3_FACT_CT_LYLTY_BEHAVIOR(ID_TRN,IC_LN_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_CT_LYLTY_BEHAVIOR
	ADD  FOREIGN KEY (ID_BSN_UN) REFERENCES DW3_DIM_BUSINESS_UNIT(ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_CT_LYLTY_BEHAVIOR
	ADD  FOREIGN KEY (ID_CT) REFERENCES DW3_DIM_CT(ID_CT)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_CT_LYLTY_BEHAVIOR
	ADD  FOREIGN KEY (ID_CHNL) REFERENCES DW3_DIM_CHNL(ID_CHNL)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_INVENTORY
	ADD  FOREIGN KEY (ID_LCN,ID_BSN_UN) REFERENCES DW3_DIM_INVENTORY_LOCATION(ID_LCN,ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_INVENTORY
	ADD  FOREIGN KEY (ID_ITM) REFERENCES DW3_DIM_ITM(ID_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_INVENTORY
	ADD  FOREIGN KEY (ID_ST_INV) REFERENCES CO_ST_INV(ID_ST_INV)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_INVENTORY
	ADD  FOREIGN KEY (ID_PRD_RP) REFERENCES CA_PRD_RP(ID_PRD_RP)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_INVENTORY
	ADD  FOREIGN KEY (ID_CTR_RVN_CST) REFERENCES CO_CTR_RVN_CST(ID_CTR_RVN_CST)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_LCN,ID_BSN_UN) REFERENCES DW3_DIM_INVENTORY_LOCATION(ID_LCN,ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_BSN_UN) REFERENCES DW3_DIM_BUSINESS_UNIT(ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_CT) REFERENCES DW3_DIM_CT(ID_CT)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_ITM) REFERENCES DW3_DIM_ITM(ID_ITM)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_CHNL) REFERENCES DW3_DIM_CHNL(ID_CHNL)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_PRM_OFR_1) REFERENCES DW3_DIM_PROMOTION(ID_PRM_OFR)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_PRM_OFR_2) REFERENCES DW3_DIM_PROMOTION(ID_PRM_OFR)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_PRM_OFR_3) REFERENCES DW3_DIM_PROMOTION(ID_PRM_OFR)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_PRM_OFR_4) REFERENCES DW3_DIM_PROMOTION(ID_PRM_OFR)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_PRM_OFR_5) REFERENCES DW3_DIM_PROMOTION(ID_PRM_OFR)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (ID_METAR_WTHR_CN) REFERENCES CO_METAR_WTHR_CN(ID_METAR_WTHR_CN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (CD_RSN) REFERENCES CO_CD_RSN(CD_RSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (CD_RSN_1) REFERENCES CO_CD_RSN(CD_RSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (CD_RSN_2) REFERENCES CO_CD_RSN(CD_RSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (CD_RSN_3) REFERENCES CO_CD_RSN(CD_RSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (CD_RSN_4) REFERENCES CO_CD_RSN(CD_RSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SALE_RTN_BEHAVIOR
	ADD  FOREIGN KEY (CD_RSN_5) REFERENCES CO_CD_RSN(CD_RSN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_SMP_CR_DB_CRD_SPND
	ADD  FOREIGN KEY (ID_CT) REFERENCES DW3_DIM_CT(ID_CT)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_TENDER_BEHAVIOR
	ADD  FOREIGN KEY (ID_BSN_UN) REFERENCES DW3_DIM_BUSINESS_UNIT(ID_BSN_UN)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_TENDER_BEHAVIOR
	ADD  FOREIGN KEY (ID_CT) REFERENCES DW3_DIM_CT(ID_CT)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go




ALTER TABLE DW3_FACT_TENDER_BEHAVIOR
	ADD  FOREIGN KEY (ID_CHNL) REFERENCES DW3_DIM_CHNL(ID_CHNL)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
go

--------------------------------------------------------------------------------
-- End of ARTS DWM 3 Database Definition  2014-01-16                          --
--------------------------------------------------------------------------------
