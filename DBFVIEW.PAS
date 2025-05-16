{ AUTEUR            : AVONTURE CHRISTOPHE ... AVC SOFTWARE

  BUT DU PROGRAMME  : * IMPRIMER LES NOMS, TYPES, LONGUEURS ET DECIMALES DE
                                 CHAQUE CHAMPS QUI CONSTITUENT LA DBF

                      * AFFICHER CES MEMES INFORMATIONS AVEC LA POSSIBILITE
                                 DE VOIR LE CONTENU DE CES CHAMPS

  DATE DE REDACTION : MERCREDI 15 NOVEMBRE 1994
  DERNIERE MODIF.   : DIMANCHE 20 NOVEMBRE 1994

  REMARQUES         : L'IMPRESSION NE CONCERNE QUE LES DESCRIPTIONS DES
                      CHAMPS ET NON LEUR CONTENU !!!

           POURQUOI : CAR LE BUT PREMIER DE CE LOGICIEL ETAIT, NON PAS, DE
                      LISTER UN DBF MAIS DE ME PERMETTRE DE CONNAITRE LE
                      NOM, DESCRIPTION ET TAILLE DES CHAMPS

                      => LA MISE EN PAGE A L'IMPRESSION EST DE CE FAIT
                         ENCORE A ECRIRE POUR GONFLER CE LOGICIEL }

Uses Video2, FileList, Printer;

Const X : Byte = 7;                   { Coordon‚e de la fenˆtre de contenu }

Type Dbf_Header = Record
       Dbf_Version : Byte;
                                       { Bit 0-2 : Nø de version de DBase
                                         Bit 3-5 : R‚serv‚s … SQL
                                         Bit 6-7 : Pr‚sence d'un champ m‚mo }
       Dbf_Annee   : Byte;                { Date de la derniŠre mise … jour }
       Dbf_Mois    : Byte;
       Dbf_Jour    : Byte;
       Dbf_NbrEnreg: LongInt;             { Nbr d'enregistrements }
       Dbf_ByteHead: Word;                { Nbr de byte de l'header }
       Dbf_ByteRec : Word;                { Nbr de byte d'un record }
       Dbf_XXX1    : Word;                { R‚serv‚ }
       Dbf_Transact: Byte;                { RepŠre une transaction inachev‚e }
       Dbf_Encrypt : Byte;                { RepŠre d'encryptage }
       Dbf_Network : Array[0..11] of Byte;{ Pour r‚seau local }
       Dbf_Mdx     : Byte;                { RepŠre pour fichier MDX   0 ou 1 }
       Dbf_XXX2    : Array[0..2] of Byte; { R‚serv‚s }
     End;

     Dbf_Champs = Record
       Dbf_NChamps : Array[0..10] of Byte;{ Nom du Champs en ASCII }
       Dbf_TChamps : Byte;                { Type : C,D,F,L,M,N }
       Dbf_XXX3    : LongInt;             { R‚serv‚s }
       Dbf_LChamps : Byte;                { Longueur du champs }
       Dbf_DChamps : Byte;                { Nbr de d‚cimale }
       Dbf_XXX4    : Word;                { R‚serv‚s }
       Dbf_ZChamps : Byte;                { Identificateur de zone de trav. }
       Dbf_XXX5    : Array[0..10] of Byte;{ R‚serv‚s }
     End;

     Buffer = Array[0..32768] of Byte;    { Buffer pour la lecture des rec. }

Var Fich           : File;
    Head           : ^Dbf_Header;         { Pointeur sur l'en-tˆte du DBF }
    Field          : ^Dbf_Champs;         { Pointeur sur le type Champs }
    Stri           : ^String;             { Variable de travail de type ptr }
    Buf            : ^Buffer;             { Buffer pour la lecture }
    I, OldX        : Byte;                { Variables de travail }
    J              : Word;                { Variable de travail }
    Max            : Byte;                { Nbr max de lignes par ‚cran }
    Debut          : LongInt;             { Emplacement du premier record }
    Actuelle       : LongInt;             { Sauvegarde de la position }
    Sortie         : String;              { Ecran ou Imprimante }
    Tempo, Tempo2  : String;              { Variables de travail }
    Dbf_Nbr_Champs : Byte;                { Nbr de champs du fichier DBF }
    NomF           : String;              { Nom du fichier DBF }
    Dbf_Nom_Champs : Array[0..50] of String[11]; { Nom de chaque champs }
    Dbf_Typ_Champs : Array[0..50] of Char; { Type des champs L, C, M, ... }
    Dbf_Tai_Champs : Array[0..1,1..50] of Word;

    { La taille du champs est cod‚e en [0,x] et son d‚placement depuis le
      d‚but du record actuellement lu en [1,x]

      Par exemple : NOM     CaractŠre  24
                    PRENOM  CaractŠre  20
                    ADRESSE CaractŠre  58

      La premiŠre  donn‚e est NOM     et son d‚placement est 0 puisque premier
      La seconde   donn‚e est PRENOM  et son d‚placement est de 24
      La troisiŠme donn‚e est ADRESSE et son d‚placement est de 44
         (somme deux premiŠres longueur) }

Function Oui_Non (Chiffre : Word) : String;

{ Renvoie 'Oui' si le chiffre donn‚ comme argument est ‚gal … 1, 'Non' dans
  les autres cas ) }

Begin

  If Chiffre = 1 then Oui_Non := 'Oui'
  Else Oui_Non := 'Non';

End;

Procedure Affiche_Header;

Begin

    BlockRead (Fich, Head^, 32);                     { Lecture de l'en-tˆte }
    Dbf_Nbr_Champs := ((Head^.Dbf_ByteHead - 33) Div 32) - 1;
                     { Calcul du nombre de champs qui composent la database }

     If Not(UpCase(Sortie[1]) = 'I') then Begin

       TextAttr := 128;

       ClrScr;

       TextAttr := 155;

       Cadre (2,0,78,4, Double);                        { Dessine un cadre }

       GotoXy (2,2);
       Tempo := 'þ DBFVIEW   by   '+Decrypt(Copyright)+'     (c) NOVEMBRE 1994';
       CentreStrln (Tempo);                            { Affiche et centre }

       TextAttr := 30;

       Cadre (17,8,62,21,Double);                     { Et dessine un cadre }

       GotoXy (19,10);

    End;

    With Head^ Do Begin

             { Affichage des donn‚es qui composent l'en-tˆte du fichier DBF }

        If (UpCase(Sortie[1]) = 'I') then Begin         { Vers l'imprimante }
 
          Writeln (Lst,'Fichier : ',NomF);
          Writeln (Lst,'*******');
          Writeln (Lst, '');

          Writeln (Lst,'Nø de version de DBase          : ',Dbf_Version and 7);
          Writeln (Lst,'R‚serv‚s … SQL                  : ',((Dbf_Version and 7) shr 3));
          Writeln (Lst,'Pr‚sence d''un champ m‚mo        : ',Oui_Non((Dbf_Version and 192) shr 6));
          WriteLn (Lst,'DerniŠre modification           : ',Dbf_Jour,'/',Dbf_Mois,'/',Dbf_Annee);
          WriteLn (Lst,'Nombre d''enregistrements        : ', Dbf_NbrEnreg);
          WriteLn (Lst,'Taille de l''en-tˆte             : ', Dbf_ByteHead);
          WriteLn (Lst,'Taille d''un enregistrement      : ', Dbf_ByteRec);
          WriteLn (Lst,'RepŠre de transaction inachev‚e : ',  Dbf_Transact);
          WriteLn (Lst,'Encryptage                      : ',Oui_Non(Dbf_Encrypt));
          WriteLn (Lst,'Fichier de production MDX       : ', Oui_Non(Dbf_MDX));
        End
        Else Begin                                           { Vers l'‚cran }
          WriteStrB ('Nø de version de DBase          : ',Dbf_Version and 7);
          Gotoxy (19,11);
          WriteStrB ('R‚serv‚s … SQL                  : ',((Dbf_Version and 7) shr 3));
          Gotoxy (19,12);
          Tempo := 'Pr‚sence d''un champ m‚mo        : ' +
                     Oui_Non((Dbf_Version and 192) shr 6);
          WriteStr (Tempo);
          Gotoxy (19,13);

       { La proc‚dure WRITESTR ne supporte que des arguments de type STRING }

          Str (Dbf_Jour,Tempo);
          Tempo2 := Tempo;
          Str (Dbf_Mois,Tempo);
          Tempo2 := Tempo2 + '/' + Tempo;
          Str (Dbf_Annee,Tempo);
          Tempo2 := 'DerniŠre modification           : ' + Tempo2 + '/' + Tempo;
          WriteStr (Tempo2);

          Gotoxy (19,14);
          WriteStrB ('Nombre d''enregistrements        : ', Dbf_NbrEnreg);
          Gotoxy (19,15);
          WriteStrB ('Taille de l''en-tˆte             : ', Dbf_ByteHead);
          Gotoxy (19,16);
          WriteStrB ('Taille d''un enregistrement      : ', Dbf_ByteRec);
          Gotoxy (19,17);
          WriteStrB ('RepŠre de transaction inachev‚e : ',  Dbf_Transact);
          Gotoxy (19,18);
          Tempo := 'Encryptage                      : ' +
                     Oui_Non(Dbf_Encrypt);
          WriteStr (Tempo);
          Gotoxy (19,19);
          Tempo := 'Fichier de production MDX       : ' +
                     Oui_Non(Dbf_MDX);
          WriteStr (Tempo);

          CopyPage (0,3);

          Ch := ReadKey; If Ch = #0 then Ch := Readkey; Ch := #0;

        End;

     End;
End;

Procedure Affiche_Champs;

Begin

    If Not (UpCase(Sortie[1]) = 'I') then Begin

               { Affichage des donn‚es contenues dans d‚finition de champs }

        TextAttr := 128;

        ClrScr;

        TextAttr := 155;

        Cadre (2,0,78,4, Double);                        { Dessine un cadre }

        GotoXy (2,2);
        Tempo := 'þ DBFVIEW   by   '+Decrypt(Copyright)+'     (c) NOVEMBRE 1994';
        CentreStrln (Tempo);                            { Affiche et centre }

        TextAttr := 30;

        Cadre (16,7,64,23,Double);

        GotoXy (18, 9);
        WriteStr ('Nom         Type           Longueur  D‚cimale');
        GotoXy (18, 10);
        WriteStr ('---         ----           --------  --------');

    End
    Else Begin
        Writeln (Lst,'');
        Writeln (Lst,'');
        Writeln (Lst,'Nom                Type                Longueur  D‚cimale');
        Writeln (Lst,'---                ----                --------  --------');
    End;

    I := 0;

    Repeat

      Inc (I);

      BlockRead (Fich, Field^, 32);            { Lecture d'un record champs }

      GotoXy (18, 12 + ((I - 1) mod 10));

      With Field^ Do Begin            { Affichage du r‚sultat de la lecture }

        If (UpCase(Sortie[1]) = 'I') then Begin                { Impression }
           Stri := Ptr (Seg(Dbf_NChamps), Ofs (Dbf_NChamps) - 1);
           Stri^[0] := #10;
           Tempo2 := '';
           For J := 1 to 10 Do
             If Not (Stri^[J] = #0) then Tempo2 := Tempo2 + Stri^[J];
           Tempo := '';
           For J := Length (Tempo2) to 17 Do Tempo := Tempo + ' ';
           Tempo2 := Tempo2 + Tempo;
           Write (Lst,Tempo2);
           Case Chr(Dbf_TChamps) Of
             'C'  : Tempo := ' CaractŠre         ';
             'N'  : Tempo := ' Num‚rique         ';
             'F'  : Tempo := ' Virgule Flottante ';
             'D'  : Tempo := ' Date              ';
             'L'  : Tempo := ' Logical           ';
             'M'  : Tempo := ' M‚mo              ';
           End;
           For J := Length (Tempo) to 15 Do Tempo := Tempo + ' ';
           Write (Lst, Tempo);
           Write (Lst,Dbf_LChamps:7);
           WriteLn (Lst,Dbf_DChamps:9);
        End
        Else Begin                                              { Affichage }
           Stri := Ptr (Seg(Dbf_NChamps), Ofs (Dbf_NChamps) - 1);
           Stri^[0] := #11; { Sp‚cification de la longueur du nom du champs }
           WriteStr (Stri^);
           Dbf_Nom_Champs[I] := Stri^;        { Sauvegarde du nom du champs }
           Case Chr(Dbf_TChamps) Of
             'C'  : WriteStr (' CaractŠre         ');
             'N'  : WriteStr (' Num‚rique         ');
             'F'  : WriteStr (' Virgule Flottante ');
             'D'  : WriteStr (' Date              ');
             'L'  : WriteStr (' Logical           ');
             'M'  : WriteStr (' M‚mo              ');
           End;
           Dbf_Typ_Champs[I] := Chr(Dbf_TChamps);      { Sauvegarde du type }
           Str (Dbf_LChamps:5, Tempo);
           WriteStr (Tempo);
           Dbf_Tai_Champs[0,I] := Dbf_LChamps;  { Sauvegarde de la longueur }
           Str (Dbf_DChamps:3, Tempo);
           WriteStrLn (Tempo);
        End
      End;

      If (Not (UpCase(Sortie[1]) = 'I') and (((I + 10) mod 10) = 0)
       and Not (I-1 = Dbf_Nbr_Champs)) then Begin

       { Au cas o— tous les champs ne peuvent ˆtre affich‚s en une seule
         fois }

         GotoXy (3,24);
         TextAttr := 139;
         WriteStr ('Appuyez sur une touche pour voir la suite...');
         TextAttr := 30;
         Ch := Readkey; If Ch = #0 then Ch := Readkey;

         TextAttr := 30;

         ClrScrWin (17,11,63,22);

      End;

      { Calcul du d‚placement du champs par rapport au d‚but du record }

      If I = 1 then Dbf_Tai_Champs[1,I] := 0
      Else If I = 2 then Dbf_Tai_Champs[1,I] := Dbf_Tai_Champs[0,I-1]
      Else Dbf_Tai_Champs[1,I] := Dbf_Tai_Champs[1,I-1] + Dbf_Tai_Champs[0,I-1];

      { Jusqu'… ce que tous les champs de la database ait ‚t‚ pass‚ en revue }

    Until (I = Dbf_Nbr_Champs + 1);

    Ch := Readkey; If Ch = #0 then Ch := Readkey; Ch := #0;

{ ************************************************************************** }

    { DERNIER CARACTERE DU DERNIER CHAMPS = GARBAGE     ?POURQUOI }

    { LA LIGNE SUIVANTE = A RETIRER}

    DEC(Dbf_Tai_Champs[0,I]);

{ ************************************************************************** }

End;

Procedure Traitement;

{ Programme }

Begin

    New (Head);                  { Allocation de m‚moire pour les pointeurs }
    New (Field);

    Assign (Fich, NomF);                             { Ouverture du fichier }
    Reset  (Fich, 1);

    TextAttr := 128;

    ClrScr;

    TextAttrCli (False);            { Interdit le clignotement des couleurs }

    TextAttr := 155;

    Cadre (2,0,78,4, Double);                            { Dessine un cadre }

    GotoXy (2,2);
    Tempo := 'þ DBFVIEW   by   '+Decrypt(Copyright)+'     (c) NOVEMBRE 1994';
    CentreStrln (Tempo);                                { Affiche et centre }

    TextAttr := 30;

    Cadre (10,9,70,14, Double);                            { Un autre cadre }

    Gotoxy (1,11);
    CentreStrLn ('D‚sirez-vous sortir les donn‚es vers ');
    CentreStr ('l''imprimante (I) ou vers l''‚cran? (E) :  ');

    Gotoxy (60,12);
    Sortie := 'E';
    ReadStr (Sortie, 1);

    SetCursOff;                                         { Eteint le curseur }

    { O— faut-il sortir les r‚sultats : vers la console ou vers l'imprimante }

    If (UpCase(Sortie[1]) = 'I') then Begin

    { Si c'est l'imprimante qui est s‚lectionn‚e, ‚criture message Copyright }

       Write (Lst,'');
       Writeln (Lst,'þ DBFVIEW   by   ',Decrypt(MyName),'                  (c) NOVEMBRE 1994');
       Writeln (Lst,'');
       Writeln (Lst,'');

    End;

    Affiche_Header;
    Affiche_Champs;

    If Not (UpCase(Sortie[1]) = 'I') then Begin

    { Si les r‚sultats sont dirig‚s vers l'‚cran, affichage du contenu de
      chaque champs }

       GotoXy (3,24);
       TextAttr := 139;
       WriteStr ('Appuyez sur une touche pour voir le contenu des champs... ');
       Ch := Readkey; If Ch = #0 then Ch := Readkey;
       GotoXY (0,24);
       ClrEol;

       GetMem (Buf, 32768);          { Allocation de m‚moire pour le buffer }

       J := 1;

       Debut := FilePos (Fich); { Sauvegarde de l'emplacement du 1er record }

       OldX := X-1;

       Repeat

          If Not (OldX = X) then Begin

             TextAttr := 155;

             Cadre (1,X,79,23,Double);

             GotoXy (0,23);
             If X = 7 then
                Tempo := ' ' + Chr(24) + ' Pr‚c‚dent     ' + Chr(25) + ' Suivant   F5  ZOOM   F6  FIELDS  F7  HEADER '
             Else
                Tempo := ' ' + Chr(24) + ' Pr‚c‚dent     ' + Chr(25) + ' Suivant   F5  UNZOOM  F6  FIELDS  F7  HEADER ';
             CentreStr (Tempo);                { Affichage du mode d'emploi }

             OldX := X;

          End;

          BlockRead (Fich, Buf^, Head^.Dbf_ByteRec);  { Lecture d'un record }

          TextAttr := 139;

          GotoXy (5,24);
          Str (J:7, Tempo);
          Tempo := 'Current record : '+ Tempo;
          WriteStr (Tempo);                                       { Recno() }
          GotoXy (32,24);
          Str (Head^.Dbf_NbrEnreg:7, Tempo);
          Tempo := 'Number of record : '+ Tempo;
          WriteStr (Tempo);                                    { Reccount() }

          TextAttr := 155;

          GotoXy (65,X);

          If (Buf^[1] = 42) then WriteStr (' Deleted ')
          Else WriteStr ('ÍÍÍÍÍÍÍÍÍ');

          Max := (MaxLig - X) - 3;

          If (Dbf_Nbr_Champs > Max) then ClrScrWin (2,8,78,22);
          { Efface une partie de la fenˆtre active si le nombre de champs est
            sup‚rieur … 16 }

          For I := 1 to Dbf_Nbr_Champs+1 Do Begin

             { Affichage du contenu de tous les champs de ce record }

             If Not ((I mod Max) = 0) then Begin

                 { V‚rification que la ligne peut ˆtre affich‚e (si trop de
                              champs alors affichage d'une seconde fenˆtre) }

                TextAttr := 155;

                GotoXy (3, X + (I Mod Max));
                WriteStr (Dbf_Nom_Champs[I]);               { Nom du champs }
                WriteStr (':');

                TextAttr := 158;

                Stri := Ptr(Seg(Buf^),Ofs(Buf^)+Dbf_Tai_Champs[1,I]+1);
                Stri^[0] := Chr(Dbf_Tai_Champs[0,I]);

                { Le contenu du champs est connu comme ceci :

                     "DES POINTEURS VOUS FEREZ UN BON USAGE"

                  J'ai lu le record en une fois
                     => toutes les donn‚es se suivent s‚quentiellement
                     => or je connais le d‚placement de chaque donn‚e par
                        rapport au d‚but du record (donc l'offset)
                        (C'est la raison pour laquelle le tableau
                         DBF_TAI_CHAMPS est compos‚ de deux entr‚es :
                            * La longueur du champs
                            * Son d‚placement par rapport du d‚but du record)
                     => je n'ai plus qu'… ajuster le pointeur de la string.

                  Une fois la donn‚e trouv‚e, reste … sp‚cifi‚ sa longueur.

                  C'est chose faite en sp‚cifiant en octet 0 de la STRING la
                  longueur du champs en question telle qu'elle est connue par
                  le tableau DBF_TAI_CHAMPS[0,x] }

                GotoXy (17, X + (I mod Max));            { Contenu du champs }

                If (Dbf_Typ_Champs[I] = 'M') then WriteStr ('<< champs m‚mo >>')
                Else If (Dbf_Typ_Champs[I] = 'L') then Begin
                   If Stri^= '1' then WriteStr ('.T.')
                   Else WriteStr ('.F.')
                End
                Else WriteStr (Stri^);
                ClrEol;

                { Si c'est un champs M‚mo, je ne connais pas son contenu
                  Si c'est un champs Logical, 0 = False   1 = True
                  Sinon affichage du contenu }

             End
             Else Begin

                { Le nombre de champs est trop grand pour ˆtre affich‚ en
                  une seule ‚tape => affichage d'une autre fenˆtre }

                Ch := ReadKey; If Ch = #0 then Ch := ReadKey;

                ClrScrWin (2,8,78,22);

                If Ch = #27 then Break
                Else If Ch = #63 then Begin { F5 Agrandissement/Diminution fenˆtre }
                     If X = 7 then Begin
                       CopyPage (0,1);
                       TextAttr := 155;
                       ClrScrWin (2,1,78,22);
                       Cadre (1,0,79,23,Double);
                       GotoXy (0,23);
                       Tempo := ' ' + Chr(24) + ' Pr‚c‚dent     ' +
                                Chr(25) + ' Suivant     F5 UNZOOM   F6  FIELDS  F7  HEADER ';
                       CentreStr (Tempo);
                       TextAttr := 158;
                       X := 0;
                     End
                     Else Begin
                       CopyPage (1,0);
                       X := 7;
                     End;
                     Seek (Fich, FilePos(Fich) - Head^.Dbf_ByteRec);
                     BlockRead (Fich, Buf^, Head^.Dbf_ByteRec);
                     I := 0;
                     Max := (MaxLig - X) - 3;
                End;
             End;
          End;

          If Ch = #27 then Break { Si LASTKEY() = 27 => Fin prog }
{          Else If Ch = #63 then Begin OldX := X; End}
          Else If Not (Ch in [#64..#65]) then
             Begin Ch := ReadKey; If Ch = #0 then Ch := ReadKey; End;

          If Ch = #27 then Break                                   { Escape }
          Else If Ch = #71 then Begin                                { Home }
                   { La touche Home fait aller au premier record du fichier }
              Seek (Fich, Debut);
              J := 1;
          End
          Else If Ch = #79 then Begin                                 { End }
                   { La touche Home fait aller au dernier record du fichier }
              Seek (Fich, FileSize(Fich)-Head^.Dbf_ByteRec-1);
              J := Head^.Dbf_NbrEnreg;
          End
          Else If ((Ch = #72) or (Ch = #73)) then Begin            { Up Key }
               Seek (Fich, FilePos(Fich) - (Head^.Dbf_ByteRec Shl 1));
               Dec (J);
          End
          Else If Ch = #63 then Begin { F5 Agrandissement/Diminution fenˆtre }
               If X = 7 then Begin
                  CopyPage (0,1);
                  X := 0;
               End
               Else Begin
                  CopyPage (1,0);
                  X := 7;
               End;

               Seek (Fich, FilePos(Fich) - Head^.Dbf_ByteRec);
          End
          Else If Ch = #64 then Begin                      { F6 Fields Info }
               Actuelle := FilePos (Fich);
               Seek (Fich, 32);
               CopyPage (0,2);
               Affiche_Champs;
               CopyPage (2,0);
               Seek (Fich, Actuelle-Head^.Dbf_ByteRec);
          End
          Else If Ch = #65 then Begin                      { F7 Header Info }
               SetPageAct(3);
               Ch := Readkey; If Ch = #0 then Ch := ReadKey; Ch := #0;
               SetPageAct(0);
               Seek (Fich, FilePos(Fich)-(Head^.Dbf_ByteRec));
          End
          Else Begin           { Si tout autre touche, DOWN KEY est suppos‚ }
               Inc (J);
          End;

          If (J = Head^.Dbf_NbrEnreg + 1) then Begin

          { Si la fin de fichier est atteinte, je me positionne sur le
            premier record du fichier}

              Seek (Fich, Debut);
              J := 1;

          End
          Else If (J = 0) then Begin
          { Si le d‚but du fichier est atteint et que UP KEY (pr‚c‚dent), je
            me positionne sur le dernier record du fichier }

              Seek (Fich, FileSize(Fich) - Head^.Dbf_ByteRec - 2);
              J := Head^.Dbf_NbrEnreg;

          End;


      Until Ch = #27;

      FreeMem (Buf, 32768);         { R‚cup‚ration des emplacements m‚moire }

    End
    Else Writeln (Lst,'');

    Close (Fich);

    Dispose (Head);                 { R‚cup‚ration des emplacements m‚moire }
    Dispose (Field);

    TextAttr := 7;
    ClrScr;

    SetCursOn;                                        { R‚tablit le curseur }

    TextAttrCli (True);   { R‚tablit le clignotement aprŠs TextAttr := 128; }

    Affiche_Message ('DBF_VIEW V1.00',129,True);


End;

Var FFilelist : FileListP;

Begin

   If ParamCount < 1 then Begin
   { Si aucun Nom de fichier, affichage d'un shell de s‚lection de fichiers }

      With FFileList Do Begin

         X0       := 6;         { Taille              }
         X1       := 78;        {        de           }
         Y0       := 3;         {           la        }
         Y1       := 17;        {              fenˆtre}
         TAttr    := 30;        {Couleur de la fenˆtre}
         TBarre   := 57;        {Couleur de la barre  }
         Masque   := '*.DBF';   {Masque : Joker permis}  { Uniquement *.DBF }
         Attribut := $3F-$08;   {AnyFile - VolumeId   }
         ChgRep   := True;      {Revenir au r‚p Actuel}

      End;

      NomF := GetFName (FFileList);             { Lecture du nom de fichier }

      If Not (NomF = '') then Traitement;     { Si pas ESCAPE => Traitement }

   End

   Else Begin   { Un nom de fichier a ‚t‚ sp‚cifi‚ sur la ligne de commande }

      NomF := ParamStr(1);
      Traitement;

   End;

End.