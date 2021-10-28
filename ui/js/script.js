const doc = document;
const maxNameLength = 10;
const closeKey = 'Backspace'

const scoreboard =  doc.getElementById('score');
const leaderboard = doc.getElementById('leaderboard');
window.addEventListener('load', () => {
    this.addEventListener('message', e => {
        if (e.data.action == 'showScoreboard') {
            if (window.getComputedStyle(scoreboard, null).display == 'flex') {
                return console.log('You need to close the other one first')
            };
            if (e.data.players) {
                updateData(e.data.players).then((response) => {
                    if (response) {
                        doc.getElementById('leaderboard').style.display = 'flex';
                    }
                    return;
                });
            }
        } else if (e.data.action == 'showScore') {
            if (window.getComputedStyle(leaderboard, null).display == 'flex') {
                return console.log('You need to close the other one first')
            };
            updateScore(e.data.player).then((response) => {
                if (response) {
                    scoreboard.style.display = 'flex';
                }
            });
        } 
    })

    doc.addEventListener('keyup', e => {
        if (e.key == closeKey) {
            fetchNUI('close');
            if (window.getComputedStyle(leaderboard, null).display == 'flex') {
                leaderboard.style.display = 'none';
            } else if (window.getComputedStyle(scoreboard, null).display == 'flex') {
                scoreboard.style.display = 'none';
            }
        }
    })
})

const updateData = async data => {
    let count = 0;
    const leaderboard = doc.getElementById('pub-leaderboard');
    const allPlayers = doc.getElementsByClassName('lead-text');
    for (let i = allPlayers.length - 1; i >= 0; i--) {
        allPlayers[i].remove();
    }
    data[0].forEach(dataItem => {
        count += 1;
        const playerInfo = doc.createElement('span');
        playerInfo.classList.add('lead-text');
        if (dataItem.kills.length > 7) {
            return console.log('Max kill number cannot be over 7!')
        }
        if (count <= 3) {
            if (count === 1) {
                playerInfo.style.color = 'gold';
            } else if (count == 2) {
                playerInfo.style.color = 'silver';
            } else {
                playerInfo.style.color = '#cd7f32';
            }
            // Discord avatar check
            if (dataItem.discord) {
                doc.getElementById(`discord-${count}`).src = dataItem.discord;
            } else {
                doc.getElementById(`discord-${count}`).src = './default.png';
            }
            doc.getElementById(`kills-${count}`).textContent = dataItem.kills;
        }
        if (dataItem.name.length > maxNameLength) {
            playerInfo.textContent = `${count} - ${(dataItem.name).slice(0, maxNameLength - 2) + '...'} - ${dataItem.kills} kills`;
        } else {
            playerInfo.textContent = `${count} - ${dataItem.name} - ${dataItem.kills} kills`;
        }
        leaderboard.appendChild(playerInfo);
    })
    return await new Promise(function(resolve, reject){
        resolve(true);
    })
    //leaderboard.append()
}

const updateScore = async data => {
    if (data.avatar) {
        doc.getElementById('personal-avatar').src = data.avatar;
    } else {
        doc.getElementById('personal-avatar').src = './default.png';
    }

    if (data.discord.length > maxNameLength) {
        doc.getElementById('personal-name').textContent = data.discord.slice(0, maxNameLength)
    } else {
        doc.getElementById('personal-name').textContent = data.discord;
    }

    if (data.kills.length > 7 || data.deaths.length > 7 || data.kd.length > 7) {
        return console.log('Max kill number cannot be over 7!')
    }
    doc.getElementById('personal-kills').textContent = data.kills;
    doc.getElementById('personal-deaths').textContent = data.deaths;
    doc.getElementById('personal-kd').textContent = data.kd;
    return await new Promise(function(resolve, reject){
        resolve(true);
    })
}

const fetchNUI = async (cbname, data) => {
    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    };
    const resp = await fetch(`https://ev-topkill/${cbname}`, options);
    return await resp.json();
}