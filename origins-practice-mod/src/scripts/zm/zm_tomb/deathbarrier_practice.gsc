// Origins practice HUD for Plutonium T6 (PC).
// Original logic: maps/mp/zombies/_zm.gsc, lines 1454-1526 in the supplied dump.
// Replaces the monitor, not its lethal rules. Do not combine with another hook.
#include common_scripts\utility;

init()
{
    if ( getdvar( "mapname" ) != "zm_tomb" )
        return;

    precacheshader( "white" );
    replacefunc( maps\mp\zombies\_zm::player_out_of_playable_area_monitor, ::dbp_monitor );
    level thread dbp_end_game_relay();
    println( "[DB Practice] Origins monitor hook installed. Restart the map after installing." );
}

dbp_end_game_relay()
{
    level waittill( "end_game" );
    players = getplayers();
    foreach ( player in players )
        player notify( "dbp_end_game" );
}

dbp_monitor()
{
    self notify( "stop_player_out_of_playable_area_monitor" );
    self endon( "stop_player_out_of_playable_area_monitor" );
    self endon( "disconnect" );
    level endon( "end_game" );

    self.dbp_phase = 0;
    self.dbp_cycle_start = gettime();
    self.dbp_last_sample = -10000;
    self.dbp_ui = dbp_make_hud();
    // Capture this HUD instance so an old cleanup cannot delete a new HUD.
    self thread dbp_cleanup_hud( self.dbp_ui );
    self thread dbp_update_hud();

    while ( !isdefined( self.characterindex ) )
        wait 0.05;
    wait( 0.15 * self.characterindex );

    while ( true )
    {
        if ( self.sessionstate == "spectator" )
        {
            self dbp_start_wait( 3 );
            wait 3;
            continue;
        }

        if ( is_true( level.hostmigration_occured ) )
        {
            self dbp_start_wait( 3 );
            wait 3;
            continue;
        }

        self.dbp_last_sample = gettime();
        if ( !self maps\mp\zombies\_zm::in_life_brush() && ( self maps\mp\zombies\_zm::in_kill_brush() || !self maps\mp\zombies\_zm::in_enabled_playable_area() ) )
        {
            if ( !isdefined( level.player_out_of_playable_area_monitor_callback ) || self [[ level.player_out_of_playable_area_monitor_callback ]]() )
            {
                self.dbp_phase = 2;
                self maps\mp\zombies\_zm_stats::increment_map_cheat_stat( "cheat_out_of_playable" );
                self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_out_of_playable", 0 );
                self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_total", 0 );
                self playlocalsound( level.zmb_laugh_alias );
                wait 0.5;

                // Intentionally no position recheck: same behavior as stock.
                if ( get_players().size == 1 && flag( "solo_game" ) && ( isdefined( self.waiting_to_revive ) && self.waiting_to_revive ) )
                    level notify( "end_game" );
                else
                {
                    self disableinvulnerability();
                    self.lives = 0;
                    self dodamage( self.health + 1000, self.origin );
                    self.bleedout_time = 0;
                }
            }
        }

        self dbp_start_wait( 1 );
        wait 3;
    }
}

dbp_start_wait( phase )
{
    self.dbp_phase = phase;
    self.dbp_cycle_start = gettime();
}

dbp_text( x, y, scale, message )
{
    hud = newclienthudelem( self );
    hud.horzalign = "left";
    hud.vertalign = "top";
    hud.alignx = "left";
    hud.aligny = "top";
    hud.x = x;
    hud.y = y;
    hud.font = "default";
    hud.fontscale = scale;
    hud.alpha = 1;
    hud.archived = 0;
    hud.hidewheninmenu = 1;
    hud settext( message );
    return hud;
}

dbp_make_hud()
{
    ui = spawnstruct();
    ui.elements = [];
    ui.title = dbp_text( 18, 66, 1.3, "DB PRACTICE - SONDEO DE AREA" );
    ui.elements[ui.elements.size] = ui.title;
    ui.seconds = dbp_text( 18, 84, 1.8, "" );
    ui.elements[ui.elements.size] = ui.seconds;
    ui.colon = dbp_text( 31, 84, 1.8, ":" );
    ui.elements[ui.elements.size] = ui.colon;
    ui.tens = dbp_text( 40, 84, 1.8, "" );
    ui.elements[ui.elements.size] = ui.tens;
    ui.ones = dbp_text( 53, 84, 1.8, "" );
    ui.elements[ui.elements.size] = ui.ones;
    ui.unit = dbp_text( 72, 88, 1.1, "/ 3:00 s (centesimas)" );
    ui.elements[ui.elements.size] = ui.unit;
    ui.status = dbp_text( 18, 111, 1.1, "INICIALIZANDO" );
    ui.elements[ui.elements.size] = ui.status;
    ui.area = dbp_text( 18, 127, 1.1, "POSICION: ..." );
    ui.elements[ui.elements.size] = ui.area;
    ui.help = dbp_text( 18, 143, 1.0, "Apuntar + USAR: poner baliza en el suelo" );
    ui.elements[ui.elements.size] = ui.help;
    ui.warning = dbp_text( 18, 157, 1.0, "Verde = entre consultas; NO garantiza seguridad" );
    ui.elements[ui.elements.size] = ui.warning;

    // Nine camera-facing HUD squares anchored in world space, no collision.
    ui.markers = [];
    for ( i = 0; i < 9; i++ )
    {
        marker = newclienthudelem( self );
        marker setshader( "white", 2, 2 );
        marker setwaypoint( 1 );
        marker.alpha = 0;
        marker.archived = 0;
        marker.hidewheninmenu = 1;
        ui.markers[i] = marker;
        ui.elements[ui.elements.size] = marker;
    }
    ui.has_marker = 0;
    return ui;
}

dbp_cleanup_hud( ui )
{
    self waittill_any( "stop_player_out_of_playable_area_monitor", "disconnect", "dbp_end_game" );
    foreach ( hud in ui.elements )
    {
        if ( isdefined( hud ) )
            hud destroy();
    }
}

dbp_update_hud()
{
    self endon( "stop_player_out_of_playable_area_monitor" );
    self endon( "disconnect" );
    level endon( "end_game" );
    ui = self.dbp_ui;
    was_marking = 0;

    while ( true )
    {
        elapsed = gettime() - self.dbp_cycle_start;
        elapsed = int( max( 0, min( elapsed, 3000 ) ) );
        color = ( 0.15, 1, 0.2 );
        message = "ENTRE CONSULTAS";
        recent = gettime() - self.dbp_last_sample < 150;

        if ( self.dbp_phase == 0 || self.dbp_phase == 3 )
        {
            color = ( 0.6, 0.6, 0.6 );
            message = "SIN CONSULTA: INICIO / ESPECTADOR / MIGRACION";
            elapsed = 0;
        }
        else if ( self.dbp_phase == 2 )
        {
            color = ( 0.8, 0.15, 1 );
            message = "INFRACCION DETECTADA: DANO PENDIENTE";
            elapsed = 3000;
        }
        else if ( recent )
        {
            color = ( 0.8, 0.15, 1 );
            message = "CONSULTA RECIENTE (destello visual 0.15 s)";
        }

        seconds = int( elapsed / 1000 );
        centiseconds = int( ( elapsed % 1000 ) / 10 );
        ui.seconds setvalue( seconds );
        ui.tens setvalue( int( centiseconds / 10 ) );
        ui.ones setvalue( centiseconds % 10 );
        ui.seconds.color = color;
        ui.tens.color = color;
        ui.ones.color = color;
        ui.colon.color = color;
        ui.status.color = color;
        ui.status settext( message );

        if ( self maps\mp\zombies\_zm::in_life_brush() )
        {
            ui.area settext( "POSICION: LIFE BRUSH (exencion del monitor)" );
            ui.area.color = ( 0.15, 1, 0.2 );
        }
        else if ( self maps\mp\zombies\_zm::in_kill_brush() )
        {
            ui.area settext( "POSICION: KILL BRUSH" );
            ui.area.color = ( 1, 0.2, 0.2 );
        }
        else if ( !self maps\mp\zombies\_zm::in_enabled_playable_area() )
        {
            ui.area settext( "POSICION: FUERA DE VOLUMEN HABILITADO" );
            ui.area.color = ( 1, 0.2, 0.2 );
        }
        else
        {
            ui.area settext( "POSICION: VOLUMEN HABILITADO" );
            ui.area.color = ( 0.15, 1, 0.2 );
        }

        marking = self adsbuttonpressed() && self usebuttonpressed();
        if ( marking && !was_marking && isalive( self ) && self.sessionstate == "playing" )
            self dbp_place_marker( ui );
        was_marking = marking;

        if ( ui.has_marker )
        {
            foreach ( marker in ui.markers )
            {
                marker.color = color;
                marker.alpha = 0.45;
            }
        }
        wait 0.05;
    }
}

dbp_place_marker( ui )
{
    start = self geteye();
    forward = anglestoforward( self getplayerangles() );
    finish = start + vectorscale( forward, 1024 );
    trace = bullettrace( start, finish, 0, self );
    if ( trace["fraction"] >= 1 )
        return;
    normal = trace["normal"];
    // Require a mostly upward-facing surface: aim at the floor.
    if ( normal[2] < 0.5 )
        return;

    center = trace["position"] + ( 0, 0, 8 );
    for ( i = 0; i < 9; i++ )
    {
        column = i % 3;
        row = int( i / 3 );
        pos = center + ( ( column - 1 ) * 32, ( row - 1 ) * 32, 0 );
        ui.markers[i].x = pos[0];
        ui.markers[i].y = pos[1];
        ui.markers[i].z = pos[2];
    }
    ui.has_marker = 1;
}
