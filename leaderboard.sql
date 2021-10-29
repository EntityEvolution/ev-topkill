CREATE TABLE `ev_leaderboard` (
    `license`       VARCHAR(255) NOT NULL,
    `kills`         INTEGER(7) NOT NULL DEFAULT 0,
    `deaths`        INTEGER(7) NOT NULL DEFAULT 0,
    `headshots`     INTEGER(7) NOT NULL DEFAULT 0,
    `avatar`        VARCHAR(255) NOT NULL DEFAULT 'https://fishii.is-horny.wtf/lbRZZ67CE1',
    `name`          VARCHAR(16) NOT NULL DEFAULT 'Unknown',
    PRIMARY KEY (`license`)
);