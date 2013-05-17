# TKT-HoN - AI for Games III platform

## How to create own team

Step 1: Fork this repository.
Step 2: Copy teams/template to teams/nameOfTeam

## TEAMS

    BindImpulse game SPACE Cmd "ServerPause"
    BindImpulse game SHIFT+SPACE Cmd "\"ServerUnpause\""
    BindImpulse game SUBTRACT Cmd "\"LevelMax"
    BindImpulse game NUM0 Cmd "\"go\""
    BindImpulse game NUM4 Cmd "host_timescale 0.1;cam_scrollSpeed 30000.0000"
    BindImpulse game NUM7 Cmd "host_timescale 0.5;cam_scrollSpeed 6000.0000"
    BindImpulse game NUM8 Cmd "host_timescale 1;cam_scrollSpeed 3000.0000"
    BindImpulse game NUM9 Cmd "host_timescale 10;cam_scrollSpeed 300.0000"

    Alias "tournament" "set teambotmanager_mode; set teambotmanager_legion; set teambotmanager_hellbourne; BotDebugEnable; StartGame practice test mode:botmatch map:caldavar teamsize:5 spectators:1 allowduplicate:true; g_botDifficulty 3; g_camDistanceMax 10000; g_camDistanceMaxSpectator 10000;"

    Alias "team_2easy_hellbourne" "set teambotmanager_hellbourne; AddBot 2 2easy_Andromeda; AddBot 2 2easy_PlaguePlague; AddBot 2 2easy_5v5_MoonQueen; AddBot 2 2easy_Hammer; AddBot 2 2easy_Dampeer"
    Alias "team_2easy_legion" "set teambotmanager_legion; AddBot 1 2easy_Andromeda; AddBot 1 2easy_PlaguePlague; AddBot 1 2easy_5v5_MoonQueen; AddBot 1 2easy_Hammer; AddBot 1 2easy_Dampeer"
    Alias "team_Botswana_hellbourne" "set teambotmanager_hellbourne Botswana; AddBot 2 Botswana_Rampage; AddBot 2 Botswana_PlagueRider; AddBot 2 Botswana_MoonQueen; AddBot 2 Botswana_FlintBeastwood; AddBot 2 Botswana_Magmus"
    Alias "team_Botswana_legion" "set teambotmanager_legion Botswana; AddBot 1 Botswana_Rampage; AddBot 1 Botswana_PlagueRider; AddBot 1 Botswana_MoonQueen; AddBot 1 Botswana_FlintBeastwood; AddBot 1 Botswana_Magmus"
    Alias "team_default_hellbourne" "set teambotmanager_hellbourne default; AddBot 2 Default_Rampage; AddBot 2 Default_PlagueRider; AddBot 2 Default_MoonQueen; AddBot 2 Default_Glacius; AddBot 2 Default_Rhapsody"
    Alias "team_default_legion" "set teambotmanager_legion default; AddBot 1 Default_Rampage; AddBot 1 Default_PlagueRider; AddBot 1 Default_MoonQueen; AddBot 1 Default_Glacius; AddBot 1 Default_Rhapsody"
    Alias "team_dropTableBots_hellbourne" "set teambotmanager_hellbourne drop-table-bots; AddBot 2 drop-table-bots_FlintBeastwood; AddBot 2 drop-table-bots_ForsakenArcher; AddBot 2 DropTableBots_Hacked_PlagueRider; AddBot 2 drop-table-bots_MoonQueen; AddBot 2 drop-table-bots_WitchSlayer"
    Alias "team_dropTableBots_legion" "set teambotmanager_legion drop-table-bots; AddBot 1 drop-table-bots_FlintBeastwood; AddBot 1 drop-table-bots_ForsakenArcher; AddBot 1 DropTableBots_Hacked_PlagueRider; AddBot 1 drop-table-bots_MoonQueen; AddBot 1 drop-table-bots_WitchSlayer"
    Alias "team_EKP_hellbourne" "set teambotmanager_hellbourne EKP; AddBot 2 EKP_Rampage; AddBot 2 EKP_PlagueRider; AddBot 2 EKP_MoonQueen; AddBot 2 EKP_Wildsoul; AddBot 2 EKP_Defiler"
    Alias "team_EKP_legion" "set teambotmanager_legion EKP; AddBot 1 EKP_Rampage; AddBot 1 EKP_PlagueRider; AddBot 1 EKP_MoonQueen; AddBot 1 EKP_Wildsoul; AddBot 1 EKP_Defiler"
    Alias "team_faulty_hellbourne" "set teambotmanager_hellbourne faulty; AddBot 2 Faulty_PlagueRider; AddBot 2 Faulty_Pharaoh; AddBot 2 Faulty_DementedShaman; AddBot 2 Faulty_Hammerstorm; AddBot 2 Faulty_MoonQueen"
    Alias "team_faulty_legion" "set teambotmanager_legion faulty; AddBot 1 Faulty_PlagueRider; AddBot 1 Faulty_Pharaoh; AddBot 1 Faulty_DementedShaman; AddBot 1 Faulty_Hammerstorm; AddBot 1 Faulty_MoonQueen"
    Alias "team_Mahlalasti_hellbourne" "set teambotmanager_hellbourne mahlalasti; AddBot 2 mahlalasti_amunra; AddBot 2 mahlalasti_dementedshaman; AddBot 2 mahlalasti_hammerstorm; AddBot 2 mahlalasti_rhapsody; AddBot 2 mahlalasti_soulreaper"
    Alias "team_Mahlalasti_legion" "set teambotmanager_legion mahlalasti; AddBot 1 mahlalasti_amunra; AddBot 1 mahlalasti_dementedshaman; AddBot 1 mahlalasti_hammerstorm; AddBot 1 mahlalasti_rhapsody; AddBot 1 mahlalasti_soulreaper"
    Alias "team_temaNoHelp_hellbourne" "set teambotmanager_hellbourne temaNoHelp; AddBot 2 temaNoHelp_forsakenarcher; AddBot 2 temaNoHelp_hammerstorm; AddBot 2 temaNoHelp_rhapsody; AddBot 2 temaNoHelp_pollywog; AddBot 2 temaNoHelp_PlagueRider"
    Alias "team_temaNoHelp_legion" "set teambotmanager_legion temaNoHelp; AddBot 1 temaNoHelp_forsakenarcher; AddBot 1 temaNoHelp_hammerstorm; AddBot 1 temaNoHelp_rhapsody; AddBot 1 temaNoHelp_pollywog; AddBot 1 temaNoHelp_PlagueRider"
    Alias "team_vidyan_hellbourne" "set teambotmanager_hellbourne vidyanmetamindgames; AddBot 2 Vidyan_Tempest; AddBot 2 Vidyan_VoodooJester; AddBot 2 Vidyan_PollywogPriest; AddBot 2 Vidyan_Beastwood; AddBot 2 Vidyan_Yogi"
    Alias "team_vidyan_legion" "set teambotmanager_legion vidyanmetamindgames; AddBot 1 Vidyan_Tempest; AddBot 1 Vidyan_VoodooJester; AddBot 1 Vidyan_PollywogPriest; AddBot 1 Vidyan_Beastwood; AddBot 1 Vidyan_Yogi"


Remember to ```ReloadTeamBots ; ReloadBots```
