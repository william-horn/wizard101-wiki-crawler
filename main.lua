

const root = 'https://www.wizard101central.com';
const creatureRoot = `${root}/wiki/Creature:`;

const parseCreatureStats = source => {
  const creatureStats = {};
  
  const getNamesFromIcons = icons => {
  	const nameMatches = icons.matchAll(/<img alt="\(Icon\).(.+?)\..+?"/g);
  	const names = [];

  	for (const name of nameMatches) {
  		names.push(name[1]);
  	}

    return names;
  }

  const getNamesFromAllies = alliesStr => {
  	const allies = [];
  	const allyMatches = alliesStr.matchAll(/>(.+?)<\/a>/g);

  	for (const ally of allyMatches) {
  		allies.push(ally[1]);
  	}

  	return allies;
  }
  
  // get the stats chunk of the page
  let chunk; {
  	// const opening = `<div id="mw-content-text" lang="en" dir="ltr" class="mw-content-ltr">`;
		// const closing = `</div>`
    
		// chunk = source.match(new RegExp(opening + '(.+?)' + closing))[1];

		chunk = source.match(/<div id="relative-top" style="display:inline-block; margin:9px 9px 0 0; vertical-align:top; width:252px;">(.+?)<\/div>/);
  }
  
  if (!chunk) {
    console.log('Creature stats chunk is missing');
    return creatureStats;
  } else {
  	chunk = chunk[1];
  	if (!chunk) {
  		console.log('No inner-content inside creature stats chunk');
  		return creatureStats;
  	}
  }
  
  // get the image of the creature
  let imageHTML; {
    const imageEndpoint = chunk.match(new RegExp(`<img alt=".+?" src="(.+?)"`));
    
    if (!imageEndpoint[1]) {
      console.log('Could not find image endpoint');
      return;
    }
    
    const imageUrl = root + imageEndpoint[1];
    creatureStats.image = imageUrl;
    chunk = chunk.substring(imageEndpoint.index + imageEndpoint[0].length);
  }
  
  // get the basic stats of the creature
  const basicStatMatches = chunk.matchAll(/<tr><td><b>(.+?)<\/b><\/td><td>(.+?)<\/td>/g);
  
  for (const match of basicStatMatches) {
    let statName = match[1];
    let statValue = match[2];
    
    // todo: add location path here, currently this just gives the world name
  	if (statName.match('title="Location:')) {
  		const worldName = statName.match(/>(.+?)</)[1];
  		statName = 'location';
  		statValue = worldName;
  	}

  	// change all stat names such as "Inc. Boost" to "inc_boost"
    statName = statName.replace(/\s+/g, '_').replace(/\./g, '').toLowerCase();
    
    switch (statName) {
      case 'classification':
        statValue = statValue.match(/>(.+?)</)[1];
        break;
      case 'school':
      	statValue = getNamesFromIcons(statValue);
      	break;
      case 'minion':
      	statName = 'allies';
      	statValue = getNamesFromAllies(statValue);
      	break;
      case 'school_pips':
      	statValue = getNamesFromIcons(statValue);
      	creatureStats[statName] = statValue;
      	continue;
    }

    // get stats with school identifiers (inc_boost, inc_resist, etc)
    if (statName.match('_')) {
    	const stat = {};
    	const quants = statValue.matchAll(/(\d+\%)(.+?)<br \/>/g);
    	let found = false;

    	for (const quant of quants) {
    		found = true;
    		const quantValue = quant[1];
    		const iconNames = getNamesFromIcons(quant[2]);

    		stat[quantValue] = iconNames
    	}

    	if (!found) {
    		statValue = { '?': getNamesFromIcons(statValue) };
    	} else {
    		statValue = stat;
    	}
    }

    creatureStats[statName] = statValue;
  }
  
  return creatureStats;
}




const parseCreatureDrops = source => {
	const creatureDrops = [];
	let chunk = source.match(/<div class="mw-collapsible-content"><table.+?><tr>(.+?)<\/table><\/div><\/div>/);

	if (!chunk) {
		console.log('Creature drops chunk is missing');
		return creatureDrops;
	} else {
		chunk = chunk[1];
		if (!chunk) {
			console.log('No inner-content for creature drops chunk');
			return creatureDrops;
		}
	}


	const dropLists = chunk.matchAll(/<tr><td><b>(.+?)<\/b>(.+?)<\/td>/g);

	for (const dropList of dropLists) {
		const listName = dropList[1].replace(/\s+/g, '_').toLowerCase();
		const listContent = dropList[2];

		const dropsHTML = listContent.matchAll(/<br \/><a href="(.+?)".+?>(.+?)</g);
		const dropContent = [];

		for (const dropData of dropsHTML) {
			const dropUrl = root + dropData[1];
			const dropName = dropData[2];

			dropContent.push({
				name: dropName,
				url: dropUrl,
				dropTrials: 0, 
				dropSuccesses: 0, 
				avgDropRate: 0
			})
		}

		creatureDrops.push({
			category: listName,
			items: dropContent
		})
	}

	return creatureDrops;
}


const scannedUrls = [
	`https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Hired+Hoof+%28Ice%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Justicon+%28Fire%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Lady+Tanselle+DreamingStar+%28Tier+5%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Maudit+Soulban#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=N.+Bison+%28Tier+4%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Person+4#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Renegade+Druid+%28Moon%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Shadow+Trickster+%28Retired%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Spike+the+Crusher#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=The+Rain+Core#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Unforgiven+Dead+%28Star%29+%28Tier+3%29#mw-pages`,
  `https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Woodland+Watcher#mw-pages`,
]


(async () => {
  const res = await fetch('https://www.wizard101central.com/wiki/index.php?title=Category:Creatures&pagefrom=Hired+Hoof+%28Ice%29#mw-pages');
  const html = await res.text();

  const matches = html.matchAll(/title="Creature:(.+?)"/g);
  // const first = matches.next();
  let iterations = 0;
  let creatureData = [];

  // for (let i = 0; i < 205; i++) {
  // 	matches.next();
  // }

  for (const match of matches) {
  	iterations++;
  	console.log('ITERATION: ', iterations);
  	// if (iterations > 50) break;

    const creatureName = match[1];
    const creatureProfileUrl = creatureRoot + creatureName.replace(/\s+/g, '_');
    const creatureProfileRes = await fetch(creatureProfileUrl);
    const creatureProfileHTML = await creatureProfileRes.text();
    
    const parsedCreatureStats = parseCreatureStats(creatureProfileHTML);
    const parsedCreatureDrops = parseCreatureDrops(creatureProfileHTML);
    console.log('CREATURE: ', creatureName);
    console.log('STATS: ')
    console.log(parsedCreatureStats);
    console.log('DROPS: ');
    console.log(parsedCreatureDrops);
    console.log('-------------------------------------------------------------------------');

    creatureData.push({
    	name: creatureName,
    	url: creatureProfileUrl,
    	stats: parsedCreatureStats,
    	drops: parsedCreatureDrops
    })

  	if (iterations%50 === 0) {
  		// console.log('SAVING AND POSTING...');
			// await fetch('https://raven-official.vercel.app/api/creatures?bulk=true', {
			// 	method: 'POST',
			// 	body: JSON.stringify(creatureData),
			// 	headers: {
			// 	  'Content-Type': 'application/json'
			// 	}
			// })

			// creatureData = [];
  	}
  }

	console.log('FINAL RESULT:');
  console.log(creatureData);
})();


	// fetch('https://raven-official.vercel.app/api/test', {
	// 	method: 'GET',
	// 	headers: {
	// 	  'Content-Type': 'application/json'
	// 	}
	// })
	// 	.then(res => res.json())
	// 	.then(data => console.log(data));
