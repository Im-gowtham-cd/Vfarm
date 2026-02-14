import HomeStyle from './page.module.css'
import Image from 'next/image'

import i1 from '../../assests/images/1.jpeg'
import i2 from '../../assests/images/2.jpeg'
import i3 from '../../assests/images/3.jpeg'
import i4 from '../../assests/images/4.jpeg'
import i5 from '../../assests/images/5.jpeg'
import h1 from '../../assests/images/H1.png'

export default function App() {

    const navLinks = ['Home', 'About', 'Features', 'How it works ?']

    const stats = [
        '1 K+ Downloads', '500+ Users', 'Secure', 'Trusted',
        '24/7 Support', 'Easy to Use', 'Reliable',
        'Cloud Based', 'Affordable', 'Verified'
    ]

    const aboutList = [
        "VFarm is a next-generation agri-tech platform redefining how farmers access knowledge, resources, and opportunities.",
        "Built for the real needs of farmers, VFarm delivers powerful tools in a simple mobile experience.",
        "Our vision is to digitize agriculture at the grassroots level with multilingual support.",
        "We are enabling a future where agriculture is data-driven and resilient."
    ]

    const features = [
        { t: 'Smarter Decisions', d: 'AI-powered insights that guide every step.' },
        { t: 'Effortless Access', d: 'Government schemes simplified.' },
        { t: 'Know the Weather', d: 'Real-time forecasts.' },
        { t: 'Sell Smarter', d: 'Live market prices.' },
        { t: 'All Documents', d: 'Secure digital storage.' },
        { t: 'Community', d: 'Learn from farmers.' },
        { t: 'Expert Help', d: 'Advice when needed.' },
        { t: 'Track Progress', d: 'Monitor growth.' },
        { t: 'Private & Secure', d: 'Your data is protected.' }
    ]

    const HIWCard = [
        {
            t: '01 — Sign Up & Set Up',
            d: 'Create your account and add farm details like location, crops, and soil type. Your personalized journey starts here.',
            m: i1
        },
        {
            t: '02 — Get Smart Recommendations',
            d: 'Receive AI-powered suggestions, weather insights, and crop guidance tailored to your farm.',
            m: i2
        },
        {
            t: '03 — Apply for Schemes',
            d: 'Find schemes, check eligibility, and apply easily with guided steps.',
            m: i3
        },
        {
            t: '04 — Track Your Farm',
            d: 'Log activities, upload documents, and monitor crop progress.',
            m: i4
        },
        {
            t: '05 — Connect with Experts',
            d: 'Get advice from agricultural experts and experienced farmers.',
            m: i5
        },
        {
            t: '06 — Grow Smarter Each Season',
            d: 'Use analytics and insights to boost yields every season.',
            m: i1
        }
    ]

    return (
        <div className={HomeStyle.HomeCenter}>

            <nav className={HomeStyle.nav}>
                <h1>V Farm</h1>
                <ul>
                    {navLinks.map((link, i) => (
                        <a key={i} href="">{link}</a>
                    ))}
                </ul>
                <a href="">Download<i className="bx bx-arrow-to-bottom" /></a>
            </nav>

            <div className={HomeStyle.HomeContainer}>
                <section className={HomeStyle.Home}>
                    <div className={HomeStyle.HomeContext}>
                        <p>We Farm , We Evolve</p>
                        <p>
                            V Farm makes farming simple with easy tools and instant access to schemes, weather, and expert advice.
                        </p>
                        <ul>
                            <a href="">Explore <i className="bx bx-arrow-in-right-circle-half" /></a>
                        </ul>
                    </div>

                    <div className={HomeStyle.HomeImage}>
                        <div className={HomeStyle.HomeCaro}>
                            <div className={HomeStyle.Card}>
                                <Image src={h1} alt="Farm" className={HomeStyle.img} />
                                <ul>
                                    <p>Community Chat</p>
                                    <p>The community feature that helps farmers connect.</p>
                                    <span>
                                        <button>Next <i className="bx bx-arrow-in-right-circle-half" /></button>
                                    </span>
                                </ul>
                            </div>
                        </div>
                    </div>
                </section>

                <div className={HomeStyle.HomeDownload}>
                    <div className={HomeStyle.Carosel}>
                        {stats.map((s, i) => <p key={i}>{s}</p>)}
                    </div>
                    <div className={HomeStyle.Carosel} aria-hidden>
                        {stats.map((s, i) => <p key={i}>{s}</p>)}
                    </div>
                </div>
            </div>

            <section className={HomeStyle.AboutContainer}>
                <p className={HomeStyle.AboutApplication}>About -- V Farm</p>
                <ul className={HomeStyle.AboutContext}>
                    {aboutList.map((text, i) => (
                        <li key={i}>{i + 1}) {text}</li>
                    ))}
                </ul>

                <div className={HomeStyle.DownloadButtonContainer}>
                    <button>Download <i className="bx bx-arrow-to-bottom" /></button>
                    <button>Version <i className="bx bx-layers-down-right" /></button>
                </div>

            </section>

            <section className={HomeStyle.FeatureContainer}>
                <p className={HomeStyle.FeatureText}>Features</p>
                <div className={HomeStyle.FeatureCardContainer}>
                    {features.map((f, i) => (
                        <div key={i} className={HomeStyle.FeatureCard}>
                            <p>{f.t}</p>
                            <p>{f.d}</p>
                        </div>
                    ))}
                </div>
            </section>

            <section className={HomeStyle.HIWContainer}>
                <p>How it works ?</p>
                <div className={HomeStyle.HIWCardContainer}>
                    {HIWCard.map((h, i) => (
                        <div key={i} className={HomeStyle.HIWCard}>
                            <p>{h.t}</p>
                            <p>{h.d}</p>
                            <div className={HomeStyle.HIWImage}>
                                <Image src={h.m} alt={h.t} className={HomeStyle.HIWImg} />
                            </div>
                        </div>
                    ))}
                </div>
            </section>

            <section className={HomeStyle.DownaloadExeContainer}>
                <p>Download</p>
                <p>Download VFarm and take smarter farming to your fingertips.</p>
                <p>Access expert knowledge, practical tools, and real opportunities — all in one simple app built for farmers. Start your digital farming journey today.</p>
                <div className={HomeStyle.DownaloadExeCardContainer}>
                    <button><i className="bxl bx-microsoft-windows" />Donwload V Farm</button>
                    <button><i className="bxl bx-android" />Donwload V Farm</button>
                    <button><i className="bxl bx-apple" />Donwload V Farm</button>
                </div>
            </section>

            {/* <section className={HomeStyle.Footer}>
                    <p>V Farm</p>
                    <div className={HomeStyle.FooterDeveloperSection}>

                    </div>
            </section> */}

        </div>
    )
}
